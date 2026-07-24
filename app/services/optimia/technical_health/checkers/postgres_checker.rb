# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class PostgresChecker < BaseChecker
        private

        def perform_check
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          connection = ActiveRecord::Base.connection
          connection.execute('SELECT 1')
          db_latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
          status = db_latency_ms > 500 ? 'degraded' : 'healthy'

          {
            status: status,
            version: connection.select_value('SELECT version()')&.split&.slice(0, 2)&.join(' '),
            uptime_seconds: nil,
            error_count: status == 'degraded' ? 1 : 0,
            metadata: {
              db_latency_ms: db_latency_ms,
              pool_size: connection.pool.size,
              active_connections: connection.pool.connections.count(&:in_use?)
            }
          }
        end
      end
    end
  end
end
