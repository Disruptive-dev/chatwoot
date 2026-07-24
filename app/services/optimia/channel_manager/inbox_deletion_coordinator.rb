# frozen_string_literal: true

module Optimia
  module ChannelManager
    class InboxDeletionCoordinator
      def self.prepare_for_inbox_destroy!(inbox:, connection:, performed_by: nil)
        new(inbox: inbox, connection: connection, performed_by: performed_by).prepare!
      end

      def initialize(inbox:, connection:, performed_by: nil)
        @inbox = inbox
        @connection = connection
        @performed_by = performed_by
      end

      def prepare!
        @connection.with_lock do
          return if @connection.lifecycle_deleted? || @connection.lifecycle_deleting?

          previous_lifecycle = @connection.lifecycle_status
          @connection.update!(
            inbox_id: nil,
            lifecycle_status: 'archived',
            inbox_recreation_enabled: false,
            archived_at: Time.current,
            updated_by: @performed_by
          )

          AuditLogger.log(
            connection: @connection,
            action: 'archived_from_inbox_deletion',
            performed_by: @performed_by,
            from_state: @connection.state,
            metadata: {
              previous_lifecycle_status: previous_lifecycle,
              inbox_id: @inbox.id,
              source: 'chatwoot_inbox_destroy'
            }
          )

          log_event(result: 'archived')
        end
      end

      private

      def log_event(result:)
        Rails.logger.info(
          {
            event: 'optimia_connection_inbox_deletion_coordinated',
            account_id: @connection.account_id,
            connection_id: @connection.id,
            inbox_id: @inbox.id,
            instance_name: @connection.external_instance_id,
            result: result
          }.compact.to_json
        )
      end
    end
  end
end
