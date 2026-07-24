# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class EvolutionChecker < BaseChecker
        private

        def perform_check
          return not_configured unless Integrations::Evolution::Client.configured?

          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          response = Integrations::Evolution::Client.new.health_check
          latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
          healthy = response[:ok]
          status = healthy ? (latency_ms > 1000 ? 'degraded' : 'healthy') : 'critical'

          {
            status: status,
            version: response[:version],
            uptime_seconds: nil,
            error_count: healthy ? 0 : 1,
            metadata: {
              evolution_latency_ms: latency_ms,
              configured: true
            }
          }
        rescue StandardError => e
          {
            status: 'critical',
            version: nil,
            uptime_seconds: nil,
            error_count: 1,
            metadata: { configured: true, error_class: e.class.name }
          }
        end

        def not_configured
          {
            status: 'unknown',
            version: nil,
            uptime_seconds: nil,
            error_count: 0,
            metadata: { configured: false }
          }
        end
      end
    end
  end
end
