# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class BaseChecker
        CHECK_TIMEOUT_SECONDS = 10

        def check
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          payload = with_timeout { perform_check }
          latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round

          build_result(payload, latency_ms)
        rescue Timeout::Error, Timeout::ExitException
          build_result(timeout_payload, 0)
        rescue StandardError => e
          build_result(error_payload(e), 0)
        end

        private

        def with_timeout(&block)
          Timeout.timeout(CHECK_TIMEOUT_SECONDS, &block)
        end

        def build_result(payload, latency_ms)
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
        end

        def timeout_payload
          {
            status: 'degraded',
            version: nil,
            uptime_seconds: nil,
            error_count: 1,
            metadata: { error_class: 'Timeout::Error', message: 'Health check timed out' }
          }
        end

        def error_payload(error)
          {
            status: 'critical',
            version: nil,
            uptime_seconds: nil,
            error_count: 1,
            metadata: {
              error_class: error.class.name,
              message: sanitized_error_message(error)
            }
          }
        end

        def sanitized_error_message(error)
          error.message.to_s.truncate(120)
        end

        def component_key
          self.class.name.demodulize.sub('Checker', '').underscore
        end
      end
    end
  end
end
