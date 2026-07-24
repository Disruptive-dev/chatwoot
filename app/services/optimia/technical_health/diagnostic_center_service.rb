# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class DiagnosticCenterService
      COMPONENT_WEIGHT = 8

      def initialize(connection: nil)
        @connection = connection
      end

      def perform!
        checks = Orchestrator.run!(
          components: %w[evolution webhooks postgres redis sidekiq jobs scheduler],
          persist: false
        )
        connection_diag = @connection ? connection_diagnostic : {}
        score, recommendations = score_and_recommend(checks, connection_diag)

        {
          score: score,
          recommendations: recommendations,
          checks: checks,
          connection: connection_diag
        }
      end

      private

      def connection_diagnostic
        Optimia::ChannelManager::HealthMonitorService.diagnose(connection: @connection)
      end

      def score_and_recommend(checks, connection_diag)
        score = 100
        recommendations = []

        checks.each do |check|
          next if check[:status] == 'healthy'

          penalty = check[:status] == 'critical' ? COMPONENT_WEIGHT * 2 : COMPONENT_WEIGHT
          score -= penalty
          recommendations << "#{check[:component].humanize}: #{check[:status]}"
        end

        if connection_diag[:health_status].present? && connection_diag[:health_status] != 'healthy'
          score -= COMPONENT_WEIGHT
          recommendations << "Connection health: #{connection_diag[:health_status]}"
        end

        [score.clamp(0, 100), recommendations]
      end
    end
  end
end
