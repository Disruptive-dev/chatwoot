# frozen_string_literal: true

module Optimia
  module ChannelManager
    class OutboundStatusProcessor
      STATUS_PROGRESSION = {
        'sent' => 0,
        'delivered' => 1,
        'read' => 2,
        'failed' => -1
      }.freeze

      attr_reader :message, :status, :external_error, :source_id

      def initialize(message:, status:, external_error: nil, source_id: nil)
        @message = message
        @status = status.to_s
        @external_error = external_error
        @source_id = source_id
      end

      def perform!
        return false unless valid_status?
        return persist_source_id_only! if duplicate_status? && source_id.present? && message.source_id.blank?
        return true if duplicate_status?
        return false if stale_transition?

        apply_updates!
        log_transition
        true
      end

      private

      def valid_status?
        Message.statuses.key?(status)
      end

      def duplicate_status?
        message.status == status
      end

      def stale_transition?
        return message.delivered? || message.read? if status == 'failed'

        current_rank = STATUS_PROGRESSION[message.status]
        new_rank = STATUS_PROGRESSION[status]
        return false if current_rank.nil? || new_rank.nil?

        current_rank >= new_rank
      end

      def apply_updates!
        message.update!(
          status: status,
          external_error: (status == 'failed' ? external_error : nil),
          source_id: resolved_source_id
        )
      end

      def resolved_source_id
        return message.source_id if source_id.blank?

        message.source_id.presence || source_id
      end

      def persist_source_id_only!
        message.update!(source_id: source_id)
        log_transition
        true
      end

      def log_transition
        connection = OptimiaChannelConnection.find_by(inbox_id: message.inbox_id)

        Rails.logger.info(
          {
            event: 'optimia_evolution_outbound_status_transition',
            message_id: message.id,
            source_id: message.source_id,
            account_id: message.account_id,
            inbox_id: message.inbox_id,
            instance_name: connection&.external_instance_id,
            status: status,
            interpreted: 'applied',
            error_present: external_error.present?
          }.compact.to_json
        )
      end
    end
  end
end
