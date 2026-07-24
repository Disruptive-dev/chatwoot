# frozen_string_literal: true

module Optimia
  module ChannelManager
    class HealthMonitorService
      MONITORABLE_STATES = %w[
        created waiting_qr waiting_scan pairing connected syncing ready
        reconnecting qr_required disconnected degraded failed error
      ].freeze

      def initialize(connection:, performed_by: nil)
        @connection = connection
        @performed_by = performed_by
      end

      def perform!
        return skip_result('monitoring_disabled') unless Integrations::Optimia::ChannelManager::MonitorConfig.monitoring_enabled?
        return skip_result('not_monitorable') unless monitorable?
        return skip_result('lock_not_acquired') unless acquire_lock!

        begin
          check_connection!
        ensure
          release_lock!
        end
      end

      def self.diagnose(connection:)
        inbox = connection.inbox
        channel = inbox&.channel
        outbound = ChatwootWebhookSyncService.diagnose(connection: connection)

        {
          connection_id: connection.id,
          account_id: connection.account_id,
          instance_name: connection.external_instance_id,
          state: connection.state,
          health_status: HealthPresenter.health_status_for(connection),
          inbox_id: inbox&.id,
          inbox_account_match: inbox.blank? || inbox.account_id == connection.account_id,
          webhook_url_configured: channel.is_a?(Channel::Api) && channel.webhook_url.present?,
          webhook_url_host: ChatwootWebhookSyncService.safe_host(channel.is_a?(Channel::Api) ? channel.webhook_url : nil),
          last_seen_at: connection.last_seen_at,
          last_state_change_at: connection.last_state_change_at,
          last_health_check_at: connection.last_health_check_at,
          reconnect_attempts_count: connection.reconnect_attempts_count,
          recent_reconnect_count: connection.recent_reconnect_count,
          masked_phone_number: HealthPresenter.masked_phone_number(connection.phone_number),
          outbound: outbound,
          recent_alerts: recent_alerts(connection),
          recent_audits: recent_audits(connection)
        }
      end

      def self.recent_alerts(connection, limit: 5)
        connection.optimia_channel_connection_alerts.recent.limit(limit).map do |alert|
          {
            id: alert.id,
            alert_type: alert.alert_type,
            message: alert.message,
            created_at: alert.created_at,
            read_at: alert.read_at
          }
        end
      end

      def self.recent_audits(connection, limit: 10)
        connection.optimia_channel_connection_audits.order(created_at: :desc).limit(limit).map do |audit|
          {
            action: audit.action,
            from_state: audit.from_state,
            to_state: audit.to_state,
            created_at: audit.created_at
          }
        end
      end

      private

      def monitorable?
        @connection.external_instance_id.present? &&
          @connection.state != 'disabled' &&
          MONITORABLE_STATES.include?(@connection.state)
      end

      def acquire_lock!
        Redis::Alfred.set(
          lock_key,
          Time.current.to_i,
          nx: true,
          ex: Integrations::Optimia::ChannelManager::MonitorConfig.connection_lock_seconds
        )
      end

      def release_lock!
        Redis::Alfred.delete(lock_key)
      end

      def lock_key
        format(::Redis::Alfred::OPTIMIA_CHANNEL_MONITOR_LOCK, connection_id: @connection.id)
      end

      def check_connection!
        adapter = Integrations::Optimia::ChannelManager::ProviderRegistry.fetch(@connection.provider)
        status = adapter.fetch_status!(connection: @connection)
        policy = ReconnectionPolicy.new(connection: @connection)
        previous_state = @connection.state

        policy.apply_from_status!(status)
        verify_webhook! if should_verify_webhook?
        touch_health_fields!

        AuditLogger.log(
          connection: @connection,
          action: 'health_checked',
          performed_by: @performed_by,
          from_state: previous_state,
          to_state: @connection.reload.state,
          metadata: { remote_state: status.remote_state }
        )

        {
          status: 'checked',
          state: @connection.state,
          remote_state: status.remote_state
        }
      rescue Integrations::Evolution::ConfigurationError => e
        ReconnectionPolicy.new(connection: @connection).apply_upstream_failure!(error_code: e.error_code)
        touch_health_fields!(error_code: e.error_code)
        { status: 'degraded', error_code: e.error_code }
      rescue StandardError => e
        ReconnectionPolicy.new(connection: @connection).apply_upstream_failure!(error_code: 'health_check_failed')
        touch_health_fields!(error_code: 'health_check_failed')
        Rails.logger.warn(
          {
            event: 'optimia_channel_health_check_failed',
            connection_id: @connection.id,
            account_id: @connection.account_id,
            error_class: e.class.name
          }.to_json
        )
        { status: 'degraded', error_code: 'health_check_failed' }
      end

      def should_verify_webhook?
        %w[ready reconnecting degraded syncing connected].include?(@connection.state) && @connection.inbox.present?
      end

      def verify_webhook!
        diagnosis = ChatwootWebhookSyncService.diagnose(connection: @connection)
        return if diagnosis[:ready_for_outbound]

        if diagnosis[:webhook_url_configured] == false
          ChatwootWebhookSyncService.new(connection: @connection, performed_by: @performed_by).perform!
        end
      rescue Optimia::ChannelManager::ChatwootWebhookSyncService::SyncError => e
        ConnectionAlertService.new(connection: @connection).notify!(
          alert_type: 'webhook_missing',
          message: I18n.t('optimia.whatsapp_connections.alerts.webhook_missing'),
          metadata: { error_code: e.error_code }
        )
        AuditLogger.log(
          connection: @connection,
          action: 'webhook_sync_failed',
          performed_by: @performed_by,
          metadata: { error_code: e.error_code }
        )
      end

      def touch_health_fields!(error_code: nil)
        attrs = {
          last_seen_at: Time.current,
          last_health_check_at: Time.current
        }
        attrs[:last_error_at] = Time.current if error_code.present?
        attrs[:last_error_code] = error_code if error_code.present?
        @connection.update!(attrs)
      end

      def skip_result(reason)
        { status: 'skipped', reason: reason }
      end
    end
  end
end
