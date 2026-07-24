# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class SidekiqChecker < BaseChecker
        private

        def perform_check
          stats = Sidekiq::Stats.new
          processes = Sidekiq::ProcessSet.new
          status = processes.any? ? 'healthy' : 'critical'
          status = 'degraded' if status == 'healthy' && stats.default_queue_latency.to_i > 30

          {
            status: status,
            version: Sidekiq::VERSION,
            uptime_seconds: nil,
            error_count: processes.any? ? 0 : 1,
            metadata: {
              processes: processes.size,
              enqueued: stats.enqueued,
              failed: stats.failed,
              sidekiq_latency_ms: (stats.default_queue_latency * 1000).round
            }
          }
        end
      end
    end
  end
end
