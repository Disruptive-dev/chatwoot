# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    module Checkers
      class DeployChecker < BaseChecker
        private

        def perform_check
          pending = ActiveRecord::Base.connection.migration_context.needs_migration?
          version = ENV.fetch('OPTIMIA_DEPLOY_VERSION', Optimia::VERSION)
          digest = ENV.fetch('OPTIMIA_DEPLOY_IMAGE_DIGEST', nil)
          tag = ENV.fetch('OPTIMIA_DEPLOY_IMAGE_TAG', Optimia::STAGING_IMAGE_TAG)

          {
            status: pending ? 'degraded' : 'healthy',
            version: version,
            uptime_seconds: nil,
            error_count: pending ? 1 : 0,
            metadata: {
              commit_sha: ENV.fetch('OPTIMIA_DEPLOY_COMMIT_SHA', nil),
              image_digest: digest,
              image_tag: tag,
              pending_migrations: pending,
              server_name: Socket.gethostname
            }
          }
        end
      end
    end
  end
end
