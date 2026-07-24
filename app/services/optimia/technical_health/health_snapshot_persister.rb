# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class HealthSnapshotPersister
      RETENTION_DAYS = 30

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

        prune_old_records!
      end

      private

      def prune_old_records!
        cutoff = RETENTION_DAYS.days.ago
        OptimiaTechnicalHealthCheck.where(checked_at: ...cutoff).delete_all
        OptimiaTechnicalMetricSnapshot.where(recorded_at: ...cutoff).delete_all
      end
    end
  end
end
