# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class SchedulerChecker < BaseChecker
        private

        def perform_check
          jobs = Sidekiq::Cron::Job.all
          enabled = jobs.count(&:enabled?)
          status = enabled.positive? ? 'healthy' : 'degraded'

          {
            status: status,
            version: nil,
            uptime_seconds: nil,
            error_count: jobs.size - enabled,
            metadata: {
              cron_jobs: jobs.size,
              enabled_jobs: enabled,
              job_names: jobs.first(10).map(&:name)
            }
          }
        end
      end
    end
  end
end
