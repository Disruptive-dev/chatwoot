# frozen_string_literal: true

module Optimia
  module FacebookComments
    class LeadCaptureService
      def initialize(account:, comment_event:, intent:, property_context:, confidence:, conversation: nil)
        @account = account
        @comment_event = comment_event
        @intent = intent
        @property_context = property_context
        @confidence = confidence
        @conversation = conversation
      end

      def perform
        return @comment_event.lead if @comment_event.lead.present?

        OptimiaFacebookCommentLead.create!(
          account: @account,
          comment_event: @comment_event,
          idempotency_key: "lead:#{@comment_event.idempotency_key}",
          page_id: @comment_event.page_id,
          post_id: @comment_event.post_id,
          comment_id: @comment_event.comment_id,
          property_id: @property_context.property_id,
          intent: @intent.to_s,
          contact_identifiers: {
            sender_id: @comment_event.sender_id
          },
          source_message_id: @comment_event.comment_id,
          confidence: @confidence,
          captured_at: Time.current,
          conversation: @conversation
        )
      end
    end
  end
end
