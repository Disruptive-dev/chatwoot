# frozen_string_literal: true

module Optimia
  module ChannelManager
    class AuditLogger
      def self.log(connection:, action:, performed_by: nil, from_state: nil, to_state: nil, metadata: {})
        OptimiaChannelConnectionAudit.create!(
          optimia_channel_connection: connection,
          account_id: connection.account_id,
          performed_by: performed_by,
          action: action,
          from_state: from_state,
          to_state: to_state,
          metadata: metadata
        )
      rescue StandardError => e
        Rails.logger.error(
          {
            event: 'optimia_channel_connection_audit_failed',
            connection_id: connection.id,
            action: action,
            error: e.message
          }.to_json
        )
      end
    end
  end
end
