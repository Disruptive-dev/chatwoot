# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class RailsChecker < BaseChecker
        private

        def perform_check
          pending = ActiveRecord::Base.connection.migration_context.needs_migration?
          status = pending ? 'degraded' : 'healthy'

          {
            status: status,
            version: "Chatwoot #{Chatwoot.config[:version]} / OptimiA #{Optimia::VERSION}",
            uptime_seconds: process_uptime_seconds,
            error_count: pending ? 1 : 0,
            metadata: {
              environment: Rails.env,
              pending_migrations: pending
            }
          }
        end

        def process_uptime_seconds
          (Time.current - $PROGRAM_START_TIME).to_i
        rescue StandardError
          nil
        end
      end
    end
  end
end
