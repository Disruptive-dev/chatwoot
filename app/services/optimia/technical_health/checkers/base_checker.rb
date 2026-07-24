# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class BaseChecker
        def check
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          payload = perform_check
          latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

          {
            component: component_key,
            status: payload[:status] || 'unknown',
            latency_ms: latency_ms,
            version: payload[:version],
            uptime_seconds: payload[:uptime_seconds],
            error_count: payload[:error_count] || 0,
            metadata: Integrations::Optimia::TechnicalHealth::Sanitizer.sanitize(payload[:metadata] || {}),
            checked_at: Time.current
          }
        rescue StandardError => e
          {
            component: component_key,
            status: 'critical',
            latency_ms: 0,
            version: nil,
            uptime_seconds: nil,
            error_count: 1,
            metadata: { error_class: e.class.name, message: e.message },
            checked_at: Time.current
          }
        end

        private

        def component_key
          self.class.name.demodulize.sub('Checker', '').underscore
        end
      end
    end
  end
end
