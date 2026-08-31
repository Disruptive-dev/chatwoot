# frozen_string_literal: true

module Optimia
  module FacebookComments
    class ObservabilityLogger
      TRACE_EVENTS = %w[
        COMMENT_RECEIVED TENANT_RESOLVED PROPERTY_RESOLVED OPTIMIA_EVALUATED
        PUBLIC_REPLY_SENT PRIVATE_REPLY_SENT LEAD_CAPTURED HANDOFF SKIPPED FAILED
      ].freeze

      def self.log(event, payload = {})
        return unless TRACE_EVENTS.include?(event.to_s)

        safe_payload = payload.except(:message_text, :access_token, :page_access_token, :user_access_token)
        Rails.logger.info({ optimia_trace: event, **safe_payload }.compact.to_json)
      end
    end
  end
end
