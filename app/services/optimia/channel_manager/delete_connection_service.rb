# frozen_string_literal: true

module Optimia
  module ChannelManager
    class DeleteConnectionService
      class ServiceError < StandardError
        attr_reader :error_code, :http_status

        def initialize(message, error_code: 'delete_failed', http_status: :unprocessable_entity)
          super(message)
          @error_code = error_code
          @http_status = http_status
        end
      end

      def initialize(connection:, performed_by:, delete_inbox: true)
        @connection = connection
        @performed_by = performed_by
        @delete_inbox = delete_inbox
        @adapter = Integrations::Optimia::ChannelManager::ProviderRegistry.fetch(@connection.provider)
      end

      def perform!
        @connection.with_lock do
          return success_payload if @connection.lifecycle_deleted?

          mark_deleting!
          disable_recreation!
          disconnect_evolution!
          remove_evolution_instance!
          clear_webhook_configuration!
          remove_inbox!
          mark_deleted!
        end

        success_payload
      rescue ServiceError
        raise
      rescue StandardError => e
        record_deletion_error!(e)
        raise ServiceError.new(sanitized_error_message(e), error_code: 'delete_incomplete')
      end

      private

      def mark_deleting!
        return if @connection.lifecycle_deleting?

        previous_lifecycle = @connection.lifecycle_status
        @connection.update!(
          lifecycle_status: 'deleting',
          deletion_requested_at: @connection.deletion_requested_at || Time.current,
          inbox_recreation_enabled: false,
          updated_by: @performed_by
        )

        AuditLogger.log(
          connection: @connection,
          action: 'deletion_started',
          performed_by: @performed_by,
          metadata: { previous_lifecycle_status: previous_lifecycle, delete_inbox: @delete_inbox }
        )
        log_event(action: 'delete', step: 'deleting')
      end

      def disable_recreation!
        @connection.update!(inbox_recreation_enabled: false) if @connection.inbox_recreation_enabled?
      end

      def disconnect_evolution!
        return if @connection.external_instance_id.blank?

        @adapter.disconnect!(connection: @connection)
      rescue StandardError => e
        log_step_warning('disconnect_evolution', e)
      end

      def remove_evolution_instance!
        return if @connection.external_instance_id.blank?
        return unless @adapter.respond_to?(:delete_instance!)

        @adapter.delete_instance!(connection: @connection)
      rescue StandardError => e
        log_step_warning('delete_evolution_instance', e)
      end

      def clear_webhook_configuration!
        inbox = @connection.inbox
        return if inbox.blank?

        channel = inbox.channel
        return unless channel.is_a?(Channel::Api)

        channel.update!(webhook_url: nil) if channel.webhook_url.present?
      rescue StandardError => e
        log_step_warning('clear_webhook', e)
      end

      def remove_inbox!
        inbox = @connection.inbox
        return if inbox.blank?

        inbox_id = inbox.id
        @connection.update!(inbox_id: nil)

        Thread.current[:optimia_inbox_destroy_performed_by] = @performed_by
        begin
          inbox.destroy! if @delete_inbox
        ensure
          Thread.current[:optimia_inbox_destroy_performed_by] = nil
        end

        AuditLogger.log(
          connection: @connection,
          action: 'inbox_removed',
          performed_by: @performed_by,
          metadata: { inbox_id: inbox_id, destroyed: @delete_inbox }
        )
      end

      def mark_deleted!
        @connection.update!(
          lifecycle_status: 'deleted',
          deleted_at: Time.current,
          deletion_completed_at: Time.current,
          deletion_error: nil,
          inbox_recreation_enabled: false,
          updated_by: @performed_by
        )

        AuditLogger.log(
          connection: @connection,
          action: 'deleted',
          performed_by: @performed_by,
          metadata: { delete_inbox: @delete_inbox }
        )
        log_event(action: 'delete', step: 'completed', result: 'success')
      end

      def record_deletion_error!(error)
        @connection.update!(
          lifecycle_status: 'error',
          deletion_error: sanitized_error_message(error),
          updated_by: @performed_by
        )

        AuditLogger.log(
          connection: @connection,
          action: 'deletion_failed',
          performed_by: @performed_by,
          metadata: { error_class: error.class.name }
        )
        log_event(action: 'delete', step: 'failed', result: 'error')
      end

      def sanitized_error_message(error)
        error.message.to_s.truncate(500)
      end

      def success_payload
        { data: @connection.reload.public_attributes }
      end

      def log_step_warning(step, error)
        Rails.logger.warn(
          {
            event: 'optimia_connection_delete_step_warning',
            step: step,
            account_id: @connection.account_id,
            connection_id: @connection.id,
            instance_name: @connection.external_instance_id,
            error_class: error.class.name
          }.to_json
        )
      end

      def log_event(action:, step:, result: nil)
        Rails.logger.info(
          {
            event: 'optimia_connection_lifecycle_action',
            action: action,
            step: step,
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
