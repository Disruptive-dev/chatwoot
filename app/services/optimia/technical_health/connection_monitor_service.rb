# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class ConnectionMonitorService
      def self.list
        OptimiaChannelConnection.administratively_visible.includes(:account, :inbox).map do |connection|
          payload(connection)
        end
      end

      def self.payload(connection)
        diagnosis = Optimia::ChannelManager::HealthMonitorService.diagnose(connection: connection)
        {
          id: connection.id,
          display_name: connection.display_name,
          provider: connection.provider,
          state: connection.state,
          lifecycle_status: connection.lifecycle_status,
          health_status: diagnosis[:health_status],
          health_score: health_score_for(connection),
          last_seen_at: connection.last_seen_at,
          last_health_check_at: connection.last_health_check_at,
          webhook_configured: diagnosis[:webhook_url_configured],
          masked_phone_number: diagnosis[:masked_phone_number]
        }
      end

      def self.health_score_for(connection)
        case Optimia::ChannelManager::HealthPresenter.health_status_for(connection)
        when 'healthy' then 100
        when 'degraded' then 60
        when 'error' then 20
        else 0
        end
      end
    end
  end
end
