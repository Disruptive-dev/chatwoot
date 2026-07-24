# frozen_string_literal: true

module Optimia
  module ChannelManager
    class RestoreConnectionService
      class ServiceError < StandardError
        attr_reader :error_code

        def initialize(message, error_code: 'restore_failed')
          super(message)
          @error_code = error_code
        end
      end

      def initialize(connection:, performed_by:)
        @connection = connection
        @performed_by = performed_by
      end

      def perform!
        raise ServiceError.new('Connection cannot be restored', error_code: 'not_restorable') unless @connection.restoration_allowed?

        @connection.with_lock do
          previous_lifecycle = @connection.lifecycle_status
          @connection.update!(
            lifecycle_status: 'active',
            inbox_recreation_enabled: true,
            archived_at: nil,
            deletion_error: nil,
            updated_by: @performed_by
          )

          AuditLogger.log(
            connection: @connection,
            action: 'restored',
            performed_by: @performed_by,
            from_state: @connection.state,
            metadata: { previous_lifecycle_status: previous_lifecycle }
          )

          log_event(result: 'success')
        end

        { data: @connection.reload.public_attributes }
      end

      private

      def log_event(result:)
        Rails.logger.info(
          {
            event: 'optimia_connection_lifecycle_action',
            action: 'restore',
            account_id: @connection.account_id,
            connection_id: @connection.id,
            instance_name: @connection.external_instance_id,
            lifecycle_status: @connection.lifecycle_status,
            result: result
          }.compact.to_json
        )
      end
    end
  end
end
