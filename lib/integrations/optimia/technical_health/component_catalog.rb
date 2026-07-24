# frozen_string_literal: true

module Integrations
  module Optimia
    module TechnicalHealth
      module ComponentCatalog
        COMPONENTS = %w[
          rails
          sidekiq
          postgres
          redis
          evolution
          docker
          storage
          jobs
          scheduler
          webhooks
          whatsapp
          deploy
        ].freeze

        STATUSES = %w[healthy degraded critical unknown].freeze
        ALERT_SEVERITIES = %w[info warning critical].freeze
        ALERT_STATUSES = %w[open acknowledged resolved].freeze
        INCIDENT_STATUSES = %w[open acknowledged resolved].freeze

        module_function

        def all
          COMPONENTS
        end
      end
    end
  end
end
