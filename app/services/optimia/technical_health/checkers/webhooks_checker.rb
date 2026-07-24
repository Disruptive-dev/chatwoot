# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class WebhooksChecker < BaseChecker
        private

        def perform_check
          connections = OptimiaChannelConnection.lifecycle_active
          broken = connections.count { |connection| webhook_broken?(connection) }
          total = connections.count
          status = broken.positive? ? (broken == total ? 'critical' : 'degraded') : 'healthy'

          {
            status: status,
            version: nil,
            uptime_seconds: nil,
            error_count: broken,
            metadata: {
              total_connections: total,
              broken_webhooks: broken
            }
          }
        end

        def webhook_broken?(connection)
          inbox = connection.inbox
          channel = inbox&.channel
          !(channel.is_a?(Channel::Api) && channel.webhook_url.present?)
        end
      end
    end
  end
end
