# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      class MonitorConfig
        DEFAULT_MONITOR_INTERVAL_SECONDS = 120
        DEFAULT_RECONNECT_MAX_ATTEMPTS = 5
        DEFAULT_ALERT_COOLDOWN_SECONDS = 3600
        DEFAULT_CONNECTION_LOCK_SECONDS = 90

        class << self
          def monitor_interval_seconds
            integer_env('OPTIMIA_CHANNEL_MANAGER_MONITOR_INTERVAL_SECONDS', DEFAULT_MONITOR_INTERVAL_SECONDS)
          end

          def reconnect_max_attempts
            integer_env('OPTIMIA_CHANNEL_MANAGER_RECONNECT_MAX_ATTEMPTS', DEFAULT_RECONNECT_MAX_ATTEMPTS)
          end

          def alert_cooldown_seconds
            integer_env('OPTIMIA_CHANNEL_MANAGER_ALERT_COOLDOWN_SECONDS', DEFAULT_ALERT_COOLDOWN_SECONDS)
          end

          def connection_lock_seconds
            integer_env('OPTIMIA_CHANNEL_MANAGER_CONNECTION_LOCK_SECONDS', DEFAULT_CONNECTION_LOCK_SECONDS)
          end

          def monitoring_enabled?
            ActiveModel::Type::Boolean.new.cast(
              ENV.fetch('OPTIMIA_CHANNEL_MANAGER_MONITORING_ENABLED', 'true')
            )
          end

          private

          def integer_env(key, default)
            value = ENV.fetch(key, nil)
            return default if value.blank?

            parsed = value.to_i
            parsed.positive? ? parsed : default
          end
        end
      end
    end
  end
end
