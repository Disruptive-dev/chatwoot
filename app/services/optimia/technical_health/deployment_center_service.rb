# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class DeploymentCenterService
      def self.current
        record = OptimiaDeploymentRecord.recent.first
        {
          version: deploy_value('OPTIMIA_DEPLOY_VERSION', Optimia::VERSION),
          commit_sha: deploy_value('OPTIMIA_DEPLOY_COMMIT_SHA', record&.commit_sha),
          image_digest: deploy_value('OPTIMIA_DEPLOY_IMAGE_DIGEST', record&.image_digest),
          image_tag: deploy_value('OPTIMIA_DEPLOY_IMAGE_TAG', record&.image_tag || Optimia::STAGING_IMAGE_TAG),
          server_name: deploy_value('OPTIMIA_SWARM_SERVICE', 'unknown'),
          deployed_at: record&.deployed_at,
          status: record&.status || 'unknown',
          history: OptimiaDeploymentRecord.recent.limit(10).map do |item|
            item.as_json(only: %i[version commit_sha image_digest image_tag environment status deployed_at])
          end,
          rollback_available: false
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
          server_name: deploy_value('OPTIMIA_SWARM_SERVICE', 'unknown'),
          deployed_at: Time.current
        )
      end

      def self.deploy_value(env_key, fallback)
        ENV.fetch(env_key, nil).presence || fallback || 'unknown'
      end
    end
  end
end
