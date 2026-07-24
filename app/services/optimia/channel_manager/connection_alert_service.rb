# frozen_string_literal: true

module Optimia
  module ChannelManager
    class ConnectionAlertService
      ALERT_TYPES = OptimiaChannelConnectionAlert::ALERT_TYPES

      def initialize(connection:)
        @connection = connection
        @account = connection.account
      end

      def notify!(alert_type:, message:, metadata: {})
        alert_type = alert_type.to_s
        return unless ALERT_TYPES.include?(alert_type)
        return nil if cooldown_active?(alert_type)

        set_cooldown(alert_type)
        alert = OptimiaChannelConnectionAlert.create!(
          optimia_channel_connection: @connection,
          account: @account,
          alert_type: alert_type,
          message: message,
          metadata: safe_metadata(metadata)
        )

        Rails.logger.info(
          {
            event: 'optimia_channel_connection_alert',
            connection_id: @connection.id,
            account_id: @account.id,
            alert_type: alert_type,
            alert_id: alert.id
          }.to_json
        )

        alert
      end

      def self.cooldown_key(connection_id, alert_type)
        format(::Redis::Alfred::OPTIMIA_CHANNEL_ALERT_COOLDOWN, connection_id: connection_id, alert_type: alert_type)
      end

      private

      def cooldown_active?(alert_type)
        Redis::Alfred.exists?(self.class.cooldown_key(@connection.id, alert_type))
      end

      def set_cooldown(alert_type)
        Redis::Alfred.set(
          self.class.cooldown_key(@connection.id, alert_type),
          Time.current.to_i,
          ex: Integrations::Optimia::ChannelManager::MonitorConfig.alert_cooldown_seconds
        )
      end

      def safe_metadata(metadata)
        metadata.stringify_keys.except('token', 'api_key', 'apikey', 'password', 'qr', 'image_base64')
      end
    end
  end
end
