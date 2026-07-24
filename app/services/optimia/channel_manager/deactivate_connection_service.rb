# frozen_string_literal: true

module Optimia
  module ChannelManager
    class DeactivateConnectionService
      class ServiceError < StandardError
        attr_reader :error_code

        def initialize(message, error_code: 'deactivate_failed')
          super(message)
          @error_code = error_code
        end
      end

      def initialize(connection:, performed_by:, lifecycle_status: 'archived')
        @connection = connection
        @performed_by = performed_by
        @lifecycle_status = lifecycle_status
      end

      def perform!
        validate!

        @connection.with_lock do
          return success_payload if already_deactivated?

          previous_lifecycle = @connection.lifecycle_status
          attrs = {
            lifecycle_status: @lifecycle_status,
            inbox_recreation_enabled: false,
            archived_at: Time.current,
            updated_by: @performed_by
          }
          @connection.update!(attrs)

          AuditLogger.log(
            connection: @connection,
            action: 'archived',
            performed_by: @performed_by,
            from_state: @connection.state,
            metadata: {
              previous_lifecycle_status: previous_lifecycle,
              lifecycle_status: @lifecycle_status
            }
          )

          log_event(action: 'deactivate', result: 'success')
        end

        success_payload
      end

      private

      def validate!
        raise ServiceError.new('Connection is being deleted', error_code: 'deleting') if @connection.lifecycle_deleting?
        raise ServiceError.new('Connection is deleted', error_code: 'deleted') if @connection.lifecycle_deleted?
      end

      def already_deactivated?
        @connection.lifecycle_archived? || @connection.lifecycle_status == 'inactive'
      end

      def success_payload
        { data: @connection.reload.public_attributes }
      end

      def log_event(action:, result:)
        Rails.logger.info(
          {
            event: 'optimia_connection_lifecycle_action',
            action: action,
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
