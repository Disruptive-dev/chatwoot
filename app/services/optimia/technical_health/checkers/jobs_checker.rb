# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class JobsChecker < BaseChecker
        private

        def perform_check
          stats = Sidekiq::Stats.new
          dead_size = Sidekiq::DeadSet.new.size
          retry_size = Sidekiq::RetrySet.new.size
          queues = Sidekiq::Queue.all.map { |queue| { name: queue.name, size: queue.size, latency_ms: (queue.latency * 1000).round } }
          max_latency = queues.pluck(:latency_ms).max.to_i
          backlog = stats.enqueued

          status = 'healthy'
          status = 'critical' if dead_size.positive? && retry_size > 100
          status = 'degraded' if status == 'healthy' && (backlog > 1000 || max_latency > 60_000)

          {
            status: status,
            version: nil,
            uptime_seconds: nil,
            error_count: dead_size,
            metadata: {
              backlog: backlog,
              dead_size: dead_size,
              retry_size: retry_size,
              queues: queues,
              workers: stats.workers_size
            }
          }
        end
      end
    end
  end
end
