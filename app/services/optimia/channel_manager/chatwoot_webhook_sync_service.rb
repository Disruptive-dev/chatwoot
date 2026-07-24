# frozen_string_literal: true

module Optimia
  module ChannelManager
    class ChatwootWebhookSyncService
      class SyncError < StandardError
        attr_reader :error_code, :http_status

        def initialize(message, error_code: 'webhook_sync_failed', http_status: :unprocessable_entity)
          super(message)
          @error_code = error_code
          @http_status = http_status
        end
      end

      READY_STATES = %w[connected syncing ready reconnecting degraded qr_required].freeze

      def initialize(connection:, performed_by: nil, resolver: nil)
        @connection = connection
        @performed_by = performed_by
        @resolver = resolver || Integrations::Optimia::ChannelManager::ChatwootWebhookResolver.new
      end

      def perform!
        validate_connection!
        inbox = @connection.inbox
        channel = inbox.channel
        raise SyncError.new('Inbox channel is not API', error_code: 'invalid_channel_type') unless channel.is_a?(Channel::Api)

        resolution = @resolver.resolve(instance_name: @connection.external_instance_id)
        webhook_url = resolution[:webhook_url]
        raise SyncError.new('Evolution webhook URL missing', error_code: 'webhook_url_missing') if webhook_url.blank?

        changed = channel.webhook_url != webhook_url
        channel.update!(webhook_url: webhook_url) if changed

        @connection.merge_metadata!(
          evolution_webhook_url: webhook_url,
          evolution_webhook_source: resolution[:source],
          webhook_synced_at: Time.current.iso8601
        )

        log_sync_event(
          inbox: inbox,
          webhook_url: webhook_url,
          source: resolution[:source],
          changed: changed,
          http_status: resolution[:http_status]
        )

        AuditLogger.log(
          connection: @connection,
          action: 'webhook_synced',
          performed_by: @performed_by,
          metadata: {
            inbox_id: inbox.id,
            webhook_source: resolution[:source],
            webhook_changed: changed
          }
        )

        {
          inbox_id: inbox.id,
          webhook_url: webhook_url,
          source: resolution[:source],
          changed: changed
        }
      end

      def self.diagnose(connection:)
        inbox = connection.inbox
        channel = inbox&.channel
        metadata = connection.connection_metadata || {}

        {
          connection_id: connection.id,
          account_id: connection.account_id,
          instance_name: connection.external_instance_id,
          state: connection.state,
          inbox_id: inbox&.id,
          channel_type: inbox&.channel_type,
          webhook_url_configured: channel.is_a?(Channel::Api) && channel.webhook_url.present?,
          webhook_url_host: safe_host(channel.is_a?(Channel::Api) ? channel.webhook_url : nil),
          evolution_webhook_url: metadata['evolution_webhook_url'],
          evolution_webhook_source: metadata['evolution_webhook_source'],
          webhook_synced_at: metadata['webhook_synced_at'],
          ready_for_outbound: ready_for_outbound?(connection, channel)
        }
      end

      def self.ready_for_outbound?(connection, channel)
        %w[ready reconnecting degraded].include?(connection.state) &&
          channel.is_a?(Channel::Api) &&
          channel.webhook_url.present? &&
          connection.external_instance_id.present?
      end

      def self.safe_host(url)
        URI.parse(url.to_s).host
      rescue URI::InvalidURIError
        nil
      end

      private

      def validate_connection!
        raise SyncError.new('Connection is not ready for webhook sync', error_code: 'invalid_state') unless READY_STATES.include?(@connection.state)
        raise SyncError.new('External instance missing', error_code: 'instance_missing') if @connection.external_instance_id.blank?
        raise SyncError.new('Inbox missing', error_code: 'inbox_missing') if @connection.inbox.blank?
        raise SyncError.new('Cross-account inbox mismatch', error_code: 'account_mismatch') if @connection.inbox.account_id != @connection.account_id
      end

      def log_sync_event(inbox:, webhook_url:, source:, changed:, http_status:)
        Rails.logger.info(
          {
            event: 'optimia_chatwoot_webhook_synced',
            connection_id: @connection.id,
            account_id: @connection.account_id,
            inbox_id: inbox.id,
            instance_name: @connection.external_instance_id,
            provider: @connection.provider,
            webhook_source: source,
            webhook_changed: changed,
            webhook_host: self.class.safe_host(webhook_url),
            evolution_find_status: http_status
          }.to_json
        )
      end
    end
  end
end
