# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class HealthSnapshotPersister
      def initialize(results)
        @results = results
      end

      def persist!
        @results.each do |result|
          OptimiaTechnicalHealthCheck.create!(
            component: result[:component],
            status: result[:status],
            latency_ms: result[:latency_ms],
            version: result[:version],
            uptime_seconds: result[:uptime_seconds],
            error_count: result[:error_count],
            metadata: result[:metadata],
            checked_at: result[:checked_at]
          )
        end
      end
    end
  end
end
