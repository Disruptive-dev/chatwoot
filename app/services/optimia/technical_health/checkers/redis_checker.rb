# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class RedisChecker < BaseChecker
        private

        def perform_check
          started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          redis = Redis.new(Redis::Config.app)
          redis.ping
          redis_latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
          info = redis.info.slice('redis_version', 'uptime_in_seconds', 'connected_clients')
          status = redis_latency_ms > 200 ? 'degraded' : 'healthy'

          {
            status: status,
            version: info['redis_version'],
            uptime_seconds: info['uptime_in_seconds']&.to_i,
            error_count: 0,
            metadata: {
              redis_latency_ms: redis_latency_ms,
              connected_clients: info['connected_clients']
            }
          }
        rescue Redis::CannotConnectError, Redis::TimeoutError
          {
            status: 'critical',
            version: nil,
            uptime_seconds: nil,
            error_count: 1,
            metadata: { redis_latency_ms: nil }
          }
        end
      end
    end
  end
end
