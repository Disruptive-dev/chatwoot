# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class DeploymentCenterService
      def self.current
        record = OptimiaDeploymentRecord.recent.first
        {
          version: ENV.fetch('OPTIMIA_DEPLOY_VERSION', Optimia::VERSION),
          commit_sha: ENV.fetch('OPTIMIA_DEPLOY_COMMIT_SHA', record&.commit_sha),
          image_digest: ENV.fetch('OPTIMIA_DEPLOY_IMAGE_DIGEST', record&.image_digest),
          image_tag: ENV.fetch('OPTIMIA_DEPLOY_IMAGE_TAG', record&.image_tag || Optimia::STAGING_IMAGE_TAG),
          server_name: ENV.fetch('OPTIMIA_SWARM_SERVICE', Socket.gethostname),
          deployed_at: record&.deployed_at,
          status: record&.status || 'unknown',
          history: OptimiaDeploymentRecord.recent.limit(10).map do |item|
            item.as_json(only: %i[version commit_sha image_digest image_tag environment status deployed_at])
          end,
          rollback_available: record.present?
        }
      end

      def self.register!(version:, commit_sha: nil, image_digest: nil, image_tag: nil, environment: 'staging', status: 'published')
        OptimiaDeploymentRecord.create!(
          version: version,
          commit_sha: commit_sha,
          image_digest: image_digest,
          image_tag: image_tag,
          environment: environment,
          status: status,
          server_name: Socket.gethostname,
          deployed_at: Time.current
        )
      end
    end
  end
end
