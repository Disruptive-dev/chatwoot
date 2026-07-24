# frozen_string_literal: true

module Optimia
  module ChannelManager
    class ConnectionCenterService
      class ServiceError < StandardError
        attr_reader :error_code, :http_status

        def initialize(message, error_code: 'connection_error', http_status: :unprocessable_entity)
          super(message)
          @error_code = error_code
          @http_status = http_status
        end
      end

      def initialize(account:, performed_by:)
        @account = account
        @performed_by = performed_by
      end

      def list_connections
        scope = @account.optimia_channel_connections.order(created_at: :desc)
        { data: scope.map(&:public_attributes) }
      end

      def create_connection(display_name:, provider: 'evolution', channel_type: 'whatsapp')
        connection = nil

        ActiveRecord::Base.transaction do
          connection = @account.optimia_channel_connections.create!(
            display_name: display_name,
            provider: provider,
            channel_type: channel_type,
            state: 'draft',
            created_by: @performed_by,
            updated_by: @performed_by
          )
          AuditLogger.log(
            connection: connection,
            action: 'created',
            performed_by: @performed_by,
            to_state: 'draft'
          )
        end

        provision_instance!(connection)
        connection.reload
        generate_qr!(connection)
      end

      def show_connection(connection)
        { data: connection.public_attributes }
      end

      def refresh_status!(connection)
        adapter = provider_for(connection)
        ensure_instance_provisioned!(connection) if connection.state.in?(%w[draft creating created])

        status = adapter.fetch_status!(connection: connection)
        apply_remote_status!(connection, status)
        connection.reload
        { data: connection.public_attributes }
      rescue Integrations::Evolution::ConfigurationError => e
        handle_configuration_error(connection, e)
      rescue StandardError => e
        handle_operation_error(connection, e, action: 'status_checked')
      end

      def generate_qr!(connection)
        adapter = provider_for(connection)
        ensure_instance_provisioned!(connection)

        connection.transition_to!('waiting_qr') if connection.can_transition_to?('waiting_qr')
        qr = adapter.fetch_qr!(connection: connection)

        connection.update!(
          qr_expires_at: qr.expires_at,
          updated_by: @performed_by
        )
        connection.clear_error!
        connection.transition_to!('waiting_scan') if connection.can_transition_to?('waiting_scan')
        connection.transition_to!('pairing') if qr.pairing_code.present? && connection.can_transition_to?('pairing')

        AuditLogger.log(
          connection: connection,
          action: 'qr_generated',
          performed_by: @performed_by,
          to_state: connection.state,
          metadata: { pairing_code_available: qr.pairing_code.present? }
        )

        {
          data: connection.public_attributes.merge(
            qr: public_qr_payload(qr)
          )
        }
      rescue Integrations::Evolution::ConfigurationError => e
        handle_configuration_error(connection, e)
      rescue StandardError => e
        handle_operation_error(connection, e, action: 'qr_generated')
      end

      def reconnect!(connection)
        connection.clear_error!
        from_state = connection.state
        connection.transition_to!('reconnecting') if connection.can_transition_to?('reconnecting')

        AuditLogger.log(
          connection: connection,
          action: 'reconnected',
          performed_by: @performed_by,
          from_state: from_state,
          to_state: connection.state
        )

        generate_qr!(connection)
      end

      def disconnect!(connection)
        adapter = provider_for(connection)
        adapter.disconnect!(connection: connection)

        from_state = connection.state
        connection.update!(
          last_disconnected_at: Time.current,
          qr_expires_at: nil,
          updated_by: @performed_by
        )
        connection.transition_to!('disconnected') if connection.can_transition_to?('disconnected')

        AuditLogger.log(
          connection: connection,
          action: 'disconnected',
          performed_by: @performed_by,
          from_state: from_state,
          to_state: connection.state
        )

        { data: connection.reload.public_attributes }
      rescue StandardError => e
        handle_operation_error(connection, e, action: 'disconnected')
      end

      def request_pairing_code!(connection, phone_number:)
        raise ServiceError.new('Pairing code not supported', error_code: 'pairing_not_supported') unless provider_for(connection).supports_pairing_code?
        raise ServiceError.new('Phone number required', error_code: 'phone_number_required') if phone_number.blank?

        adapter = provider_for(connection)
        ensure_instance_provisioned!(connection)
        client = Integrations::Evolution::Client.new
        response = client.connect_instance(connection.external_instance_id, number: phone_number)
        raise ServiceError.new(response[:error], error_code: response[:error_code]) if response[:error].present?

        qr_payload = response[:data].is_a?(Hash) ? response[:data] : {}
        pairing_code = qr_payload.dig('qrcode', 'pairingCode') || qr_payload['pairingCode']
        connection.transition_to!('pairing') if connection.can_transition_to?('pairing')

        {
          data: connection.reload.public_attributes.merge(
            pairing_code: pairing_code
          )
        }
      end

      private

      def provision_instance!(connection)
        adapter = provider_for(connection)
        from_state = connection.state
        connection.transition_to!('creating') if connection.can_transition_to?('creating')

        result = adapter.ensure_instance!(connection: connection)
        connection.update!(
          external_instance_id: result.external_instance_id,
          updated_by: @performed_by
        )
        connection.merge_credentials!(result.credentials) if result.credentials.present?
        connection.merge_metadata!(result.metadata) if result.metadata.present?
        connection.transition_to!('created') if connection.can_transition_to?('created')

        AuditLogger.log(
          connection: connection,
          action: 'instance_provisioned',
          performed_by: @performed_by,
          from_state: from_state,
          to_state: connection.state,
          metadata: { recovered: result.metadata[:recovered] }
        )
      rescue Integrations::Evolution::ConfigurationError => e
        handle_configuration_error(connection, e)
      rescue StandardError => e
        handle_operation_error(connection, e, action: 'instance_provisioned')
      end

      def ensure_instance_provisioned!(connection)
        return if connection.external_instance_id.present?

        provision_instance!(connection)
      end

      def apply_remote_status!(connection, status)
        mapped = map_remote_state(status.remote_state)
        connection.update!(phone_number: status.phone_number) if status.phone_number.present?
        connection.merge_metadata!(status.metadata) if status.metadata.present?

        case mapped
        when 'connected'
          mark_connected!(connection)
          provision_chatwoot!(connection)
        when 'waiting_scan'
          connection.transition_to!('waiting_scan') if connection.can_transition_to?('waiting_scan')
        when 'disconnected'
          connection.transition_to!('disconnected') if connection.can_transition_to?('disconnected')
        end

        AuditLogger.log(
          connection: connection,
          action: 'status_checked',
          performed_by: @performed_by,
          to_state: connection.state,
          metadata: { remote_state: status.remote_state }
        )
      end

      def mark_connected!(connection)
        from_state = connection.state
        connection.update!(last_connected_at: Time.current, updated_by: @performed_by)
        connection.transition_to!('connected') if connection.can_transition_to?('connected')

        AuditLogger.log(
          connection: connection,
          action: 'connected',
          performed_by: @performed_by,
          from_state: from_state,
          to_state: connection.state
        )
      end

      def provision_chatwoot!(connection)
        return if connection.state == 'ready'

        inbox = ProvisioningService.new(connection: connection, performed_by: @performed_by).perform!
        from_state = connection.state
        connection.transition_to!('syncing') if connection.can_transition_to?('syncing')

        AuditLogger.log(
          connection: connection,
          action: 'provisioning_started',
          performed_by: @performed_by,
          from_state: from_state,
          to_state: connection.state
        )

        adapter = provider_for(connection)
        chatwoot_config = chatwoot_config_for(inbox, connection)
        adapter.configure_chatwoot!(
          connection: connection,
          chatwoot_config: chatwoot_config
        )

        ChatwootWebhookSyncService.new(connection: connection, performed_by: @performed_by).perform!

        connection.transition_to!('ready') if connection.can_transition_to?('ready')
        AuditLogger.log(
          connection: connection,
          action: 'ready',
          performed_by: @performed_by,
          to_state: connection.state,
          metadata: { inbox_id: inbox.id }
        )
      rescue Optimia::ChannelManager::ChatwootWebhookSyncService::SyncError => e
        handle_webhook_sync_error(connection, e)
      end

      def chatwoot_config_for(inbox, connection)
        config = {
          enabled: true,
          accountId: @account.id.to_s,
          token: chatwoot_api_token,
          url: chatwoot_public_url,
          signMsg: true,
          reopenConversation: true,
          conversationPending: false,
          nameInbox: inbox.name,
          mergeBrazilContacts: true,
          importContacts: false,
          importMessages: false,
          daysLimitImportMessages: 1,
          signDelimiter: "\n",
          autoCreate: false,
          organization: @account.name.presence || 'OptimiA',
          logo: '',
          ignoreJids: []
        }

        phone_number = connection.phone_number
        config[:number] = phone_number.delete_prefix('+') if phone_number.present?

        config
      end

      def chatwoot_public_url
        url = ENV.fetch('OPTIMIA_CHATWOOT_PUBLIC_URL', nil).presence
        url ||= GlobalConfig.get('FRONTEND_URL')['FRONTEND_URL']
        url ||= ENV.fetch('FRONTEND_URL', nil)
        url.to_s.chomp('/')
      end

      def chatwoot_api_token
        token = ENV.fetch('OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN', nil).presence
        token ||= GlobalConfig.get('OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN')['OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN']
        token ||= @performed_by&.access_token&.token
        raise ServiceError.new('Chatwoot API token not configured', error_code: 'chatwoot_token_missing') if token.blank?

        token
      end

      def map_remote_state(remote_state)
        case remote_state.to_s
        when 'open' then 'connected'
        when 'connecting' then 'waiting_scan'
        when 'close' then 'disconnected'
        else remote_state.to_s
        end
      end

      def public_qr_payload(qr)
        {
          available: qr.base64.present?,
          image_base64: qr.base64,
          expires_at: qr.expires_at,
          countdown_seconds: [(qr.expires_at.to_i - Time.current.to_i), 0].max,
          pairing_code_available: qr.pairing_code.present?
        }
      end

      def provider_for(connection)
        Integrations::Optimia::ChannelManager::ProviderRegistry.fetch(connection.provider)
      end

      def handle_configuration_error(connection, error)
        connection.mark_error!(code: error.error_code, message: error.message)
        AuditLogger.log(
          connection: connection,
          action: 'error',
          performed_by: @performed_by,
          metadata: { error_code: error.error_code }
        )
        raise ServiceError.new(public_message_for(error), error_code: error.error_code, http_status: error.http_status)
      end

      def handle_operation_error(connection, error, action:)
        error_code = error.respond_to?(:error_code) ? error.error_code : 'connection_error'
        connection.mark_error!(code: error_code, message: error.message)
        AuditLogger.log(
          connection: connection,
          action: 'error',
          performed_by: @performed_by,
          metadata: { source_action: action, error: error.message }
        )
        raise ServiceError.new(error.message, error_code: error_code)
      end

      def handle_webhook_sync_error(connection, error)
        connection.mark_error!(code: error.error_code, message: error.message)
        AuditLogger.log(
          connection: connection,
          action: 'error',
          performed_by: @performed_by,
          metadata: { source_action: 'webhook_synced', error_code: error.error_code }
        )
        raise ServiceError.new(error.message, error_code: error.error_code, http_status: error.http_status)
      end

      def public_message_for(error)
        case error.error_code
        when 'evolution_not_configured'
          I18n.t('optimia.whatsapp_connections.errors.not_configured')
        when 'evolution_upstream_unavailable'
          I18n.t('optimia.whatsapp_connections.errors.upstream_unavailable')
        else
          I18n.t('optimia.whatsapp_connections.errors.generic')
        end
      end
    end
  end
end
