# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class CollectHealthJob < ApplicationJob
      queue_as :scheduled_jobs

      def perform
        Orchestrator.run!
      end
    end
  end
end
