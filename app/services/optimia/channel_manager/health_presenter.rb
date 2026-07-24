# frozen_string_literal: true

module Optimia
  module ChannelManager
    class HealthPresenter
      HEALTH_LABELS = {
        'ready' => 'operational',
        'reconnecting' => 'reconnecting',
        'qr_required' => 'qr_required',
        'degraded' => 'degraded',
        'disconnected' => 'disconnected',
        'failed' => 'error',
        'error' => 'error'
      }.freeze

      def self.health_status_for(connection)
        HEALTH_LABELS.fetch(connection.state, connection.state)
      end

      def self.masked_phone_number(phone_number)
        return nil if phone_number.blank?

        digits = phone_number.to_s.gsub(/\D/, '')
        return '****' if digits.length <= 4

        "+#{'*' * (digits.length - 4)}#{digits.last(4)}"
      end

      def self.public_health_attributes(connection)
        {
          health_status: health_status_for(connection),
          masked_phone_number: masked_phone_number(connection.phone_number),
          last_seen_at: connection.last_seen_at,
          last_state_change_at: connection.last_state_change_at,
          last_health_check_at: connection.last_health_check_at,
          reconnect_attempts_count: connection.reconnect_attempts_count,
          recent_reconnect_count: connection.recent_reconnect_count,
          webhook_configured: webhook_configured?(connection)
        }
      end

      def self.webhook_configured?(connection)
        channel = connection.inbox&.channel
        channel.is_a?(Channel::Api) && channel.webhook_url.present?
      end
    end
  end
end
