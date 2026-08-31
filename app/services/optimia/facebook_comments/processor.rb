# frozen_string_literal: true

module Optimia
  module FacebookComments
    class Processor
      def initialize(normalized_event:, correlation_id: SecureRandom.uuid)
        @event = normalized_event
        @correlation_id = correlation_id
      end

      def perform
        started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        comment_event = nil

        tenant = TenantResolver.new(page_id: @event[:page_id]).resolve
        unless tenant.resolved?
          ObservabilityLogger.log('SKIPPED', base_trace.merge(decision: 'tenant_unresolved', status: 'skipped'))
          return
        end

        ObservabilityLogger.log('TENANT_RESOLVED', base_trace.merge(
                                                     tenant_id: tenant.account.id,
                                                     page_id: @event[:page_id]
                                                   ))

        unless Integrations::Optimia::FacebookComments::Feature.comments_enabled_for_account?(tenant.account)
          ObservabilityLogger.log('SKIPPED', base_trace.merge(decision: 'feature_disabled', tenant_id: tenant.account.id))
          return
        end

        comment_event = find_or_create_event!(tenant)

        OptimiaFacebookCommentEvent.transaction do
          comment_event.lock!
          return if comment_event.terminal?

          process_event!(comment_event, tenant, started_at)
        end
      rescue StandardError => e
        comment_event&.mark_failed!(error_message: e.message)
        ObservabilityLogger.log('FAILED', base_trace.merge(
                                             error_class: e.class.name,
                                             status: 'failed'
                                           ))
        raise
      end

      private

      def process_event!(comment_event, tenant, started_at)
        comment_event.mark_processing!

        property_context = resolve_property(tenant.account)
        intent = IntentClassifier.new(@event[:message]).classify
        intent_confidence = IntentClassifier.new(@event[:message]).confidence
        handoff_active = handoff_active_for_sender?(tenant)

        policy = ResponsePolicy.new(
          intent: intent,
          property_context: property_context,
          message: @event[:message],
          account: tenant.account,
          handoff_active: handoff_active
        ).decide

        comment_event.update!(intent: intent.to_s, property_id: property_context.property_id, decision: policy_decision_label(policy))

        if policy.skip_reason.present? && !policy.should_reply
          comment_event.mark_skipped!(decision: policy.skip_reason)
          ObservabilityLogger.log('SKIPPED', trace_with_policy(policy, tenant, property_context, intent, started_at))
          return
        end

        conversation = nil
        if policy.should_handoff
          conversation = HandoffService.new(
            account: tenant.account,
            inbox: tenant.inbox,
            comment_event: comment_event
          ).perform
          comment_event.update!(conversation: conversation)
          ObservabilityLogger.log('HANDOFF', trace_with_policy(policy, tenant, property_context, intent, started_at))
        end

        if policy.should_capture_lead
          LeadCaptureService.new(
            account: tenant.account,
            comment_event: comment_event,
            intent: intent,
            property_context: property_context,
            confidence: intent_confidence,
            conversation: conversation
          ).perform
          ObservabilityLogger.log('LEAD_CAPTURED', trace_with_policy(policy, tenant, property_context, intent, started_at))
        end

        unless policy.should_reply
          finalize_without_reply(comment_event, policy, tenant, property_context, intent, started_at)
          return
        end

        reply_text = AiReplyGenerator.new(
          account: tenant.account,
          intent: intent,
          property_context: property_context,
          message: @event[:message],
          inbox: tenant.inbox
        ).generate

        ObservabilityLogger.log('OPTIMIA_EVALUATED', trace_with_policy(policy, tenant, property_context, intent, started_at))
        send_reply!(comment_event, tenant, policy, reply_text, started_at)
      end

      def find_or_create_event!(tenant)
        idempotency_key = idempotency_key_for(@event)
        existing = OptimiaFacebookCommentEvent.find_by(idempotency_key: idempotency_key)
        return existing if existing.present?

        ObservabilityLogger.log('COMMENT_RECEIVED', base_trace.merge(
                                                       tenant_id: tenant.account.id,
                                                       page_id: @event[:page_id],
                                                       post_id: @event[:post_id],
                                                       comment_id: @event[:comment_id]
                                                     ))

        OptimiaFacebookCommentEvent.create!(
          account: tenant.account,
          channel_facebook_page: tenant.channel,
          idempotency_key: idempotency_key,
          correlation_id: @correlation_id,
          page_id: @event[:page_id],
          post_id: @event[:post_id],
          comment_id: @event[:comment_id],
          parent_id: @event[:parent_id],
          sender_id: @event[:sender_id],
          message_text: @event[:message],
          event_type: @event[:event_type],
          status: 'received',
          metadata: @event[:raw_value] || {}
        )
      rescue ActiveRecord::RecordNotUnique
        OptimiaFacebookCommentEvent.find_by!(idempotency_key: idempotency_key)
      end

      def idempotency_key_for(event)
        "fb_comment:#{event[:page_id]}:#{event[:comment_id]}:#{event[:event_type]}"
      end

      def resolve_property(account)
        context = PropertyContextResolver.new(
          account: account,
          page_id: @event[:page_id],
          post_id: @event[:post_id]
        ).resolve

        ObservabilityLogger.log('PROPERTY_RESOLVED', base_trace.merge(
                                                        tenant_id: account.id,
                                                        property_id: context.property_id,
                                                        post_id: @event[:post_id]
                                                      ))
        context
      end

      def handoff_active_for_sender?(tenant)
        return false if @event[:sender_id].blank?

        Conversation.joins(:contact_inbox)
                    .where(account_id: tenant.account.id, inbox_id: tenant.inbox.id, status: :open)
                    .where("conversations.additional_attributes ->> 'optimia_facebook_comment_automation_paused' = 'true'")
                    .where(contact_inboxes: { source_id: @event[:sender_id] })
                    .exists?
      end

      def send_reply!(comment_event, tenant, policy, reply_text, started_at)
        response_id = case policy.response_mode
                      when 'public'
                        PublicReplyService.new(channel: tenant.channel).perform(
                          comment_id: @event[:comment_id],
                          message: reply_text
                        ).tap do
                          ObservabilityLogger.log('PUBLIC_REPLY_SENT', trace_with_policy(policy, tenant, nil, comment_event.intent, started_at))
                        end
                      when 'private', 'handoff'
                        PrivateReplyService.new(channel: tenant.channel).perform(
                          comment_id: @event[:comment_id],
                          message: reply_text
                        ).tap do
                          ObservabilityLogger.log('PRIVATE_REPLY_SENT', trace_with_policy(policy, tenant, nil, comment_event.intent, started_at))
                        end
                      end

        comment_event.mark_answered!(
          response_mode: policy.response_mode,
          response_comment_id: response_id,
          decision: policy_decision_label(policy)
        )
      end

      def finalize_without_reply(comment_event, policy, tenant, property_context, intent, started_at)
        comment_event.mark_skipped!(decision: policy.skip_reason || 'no_reply')
        ObservabilityLogger.log('SKIPPED', trace_with_policy(policy, tenant, property_context, intent, started_at))
      end

      def policy_decision_label(policy)
        policy.skip_reason || policy.response_mode
      end

      def base_trace
        {
          correlation_id: @correlation_id,
          page_id: @event[:page_id],
          post_id: @event[:post_id],
          comment_id: @event[:comment_id]
        }
      end

      def trace_with_policy(policy, tenant, property_context, intent, started_at)
        base_trace.merge(
          tenant_id: tenant.account.id,
          property_id: property_context&.property_id,
          intent: intent.to_s,
          decision: policy_decision_label(policy),
          response_mode: policy.response_mode,
          status: 'processing',
          latency_ms: elapsed_ms(started_at)
        )
      end

      def elapsed_ms(started_at)
        return nil unless started_at

        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round
      end
    end
  end
end
