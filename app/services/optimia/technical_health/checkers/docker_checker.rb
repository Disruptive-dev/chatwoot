# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class DockerChecker < BaseChecker
        private

        def perform_check
          service = ENV.fetch('OPTIMIA_SWARM_SERVICE', nil)
          role = ENV.fetch('OPTIMIA_NODE_ROLE', 'unknown')

          {
            status: service.present? ? 'healthy' : 'unknown',
            version: nil,
            uptime_seconds: nil,
            error_count: 0,
            metadata: {
              swarm_service: service,
              node_role: role,
              hostname: Socket.gethostname
            }
          }
        end
      end
    end
  end
end
