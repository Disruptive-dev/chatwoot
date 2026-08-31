# frozen_string_literal: true

module Optimia
  module FacebookComments
    class ResponsePolicy
      Decision = Struct.new(:response_mode, :should_reply, :should_capture_lead, :should_handoff, :skip_reason, keyword_init: true)

      HANDOFF_INTENTS = %i[handoff visit personal_data].freeze
      LEAD_INTENTS = %i[price interest info location availability visit handoff general].freeze

      def initialize(intent:, property_context:, message:, account:, handoff_active: false)
        @intent = intent
        @property_context = property_context
        @message = message.to_s
        @account = account
        @handoff_active = handoff_active
      end

      def decide
        return skip_decision('handoff_active') if @handoff_active
        return skip_decision('reaction') if @intent == :reaction
        return skip_decision('irrelevant') if @intent == :irrelevant
        return skip_decision('feature_disabled') unless Integrations::Optimia::FacebookComments::Feature.comments_enabled_for_account?(@account)

        if HANDOFF_INTENTS.include?(@intent) && @intent != :personal_data
          return handoff_decision
        end

        if @intent == :personal_data
          return private_decision(should_handoff: true)
        end

        if @intent == :visit
          return private_decision(should_handoff: true, should_capture_lead: true)
        end

        public_decision
      end

      private

      def skip_decision(reason)
        Decision.new(
          response_mode: 'none',
          should_reply: false,
          should_capture_lead: false,
          should_handoff: false,
          skip_reason: reason
        )
      end

      def handoff_decision
        Decision.new(
          response_mode: 'handoff',
          should_reply: true,
          should_capture_lead: true,
          should_handoff: true,
          skip_reason: nil
        )
      end

      def private_decision(should_handoff: false, should_capture_lead: true)
        Decision.new(
          response_mode: 'private',
          should_reply: Integrations::Optimia::FacebookComments::Feature.private_reply_enabled_for_account?(@account),
          should_capture_lead: should_capture_lead,
          should_handoff: should_handoff,
          skip_reason: nil
        )
      end

      def public_decision
        Decision.new(
          response_mode: 'public',
          should_reply: Integrations::Optimia::FacebookComments::Feature.ai_reply_enabled_for_account?(@account),
          should_capture_lead: LEAD_INTENTS.include?(@intent),
          should_handoff: false,
          skip_reason: nil
        )
      end
    end
  end
end
