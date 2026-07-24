# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class CollectHealthJob < ApplicationJob
      queue_as :scheduled_jobs

      LOCK_SECONDS = 240

      def perform
        return unless acquire_lock!

        Orchestrator.run!
      ensure
        release_lock! if @lock_acquired
      end

      private

      def acquire_lock!
        @lock_acquired = Redis::Alfred.set(
          Redis::Alfred::OPTIMIA_TECHNICAL_HEALTH_COLLECT_LOCK,
          Time.current.to_i,
          nx: true,
          ex: LOCK_SECONDS
        )
      end

      def release_lock!
        Redis::Alfred.delete(Redis::Alfred::OPTIMIA_TECHNICAL_HEALTH_COLLECT_LOCK)
      end
    end
  end
end
