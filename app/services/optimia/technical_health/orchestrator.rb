# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class Orchestrator
      CHECKERS = {
        'rails' => Checkers::RailsChecker,
        'sidekiq' => Checkers::SidekiqChecker,
        'postgres' => Checkers::PostgresChecker,
        'redis' => Checkers::RedisChecker,
        'evolution' => Checkers::EvolutionChecker,
        'docker' => Checkers::DockerChecker,
        'storage' => Checkers::StorageChecker,
        'jobs' => Checkers::JobsChecker,
        'scheduler' => Checkers::SchedulerChecker,
        'webhooks' => Checkers::WebhooksChecker,
        'whatsapp' => Checkers::WhatsappChecker,
        'deploy' => Checkers::DeployChecker
      }.freeze

      def self.run!(components: CHECKERS.keys)
        new(components: components).run!
      end

      def initialize(components: CHECKERS.keys)
        @components = components
      end

      def run!
        results = @components.filter_map do |component|
          checker_class = CHECKERS[component]
          next unless checker_class

          checker_class.new.check
        end

        HealthSnapshotPersister.new(results).persist!
        AlertDetectorService.new(results).detect!
        MetricsCollectorService.new.record_from_checks!(results)
        results
      end
    end
  end
end
