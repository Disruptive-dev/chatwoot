# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class AlertDetectorService
      RULES = [
        { type: 'qr_expired', component: 'whatsapp', severity: 'warning', check: :qr_expired? },
        { type: 'webhook_broken', component: 'webhooks', severity: 'critical', check: :webhook_broken? },
        { type: 'evolution_down', component: 'evolution', severity: 'critical', check: :evolution_down? },
        { type: 'redis_down', component: 'redis', severity: 'critical', check: :redis_down? },
        { type: 'sidekiq_stopped', component: 'sidekiq', severity: 'critical', check: :sidekiq_stopped? },
        { type: 'postgres_slow', component: 'postgres', severity: 'warning', check: :postgres_slow? },
        { type: 'storage_full', component: 'storage', severity: 'critical', check: :storage_full? },
        { type: 'deploy_incomplete', component: 'deploy', severity: 'warning', check: :deploy_incomplete? },
        { type: 'excessive_retries', component: 'jobs', severity: 'warning', check: :excessive_retries? },
        { type: 'pending_messages', component: 'jobs', severity: 'warning', check: :pending_messages? },
        { type: 'consecutive_errors', component: 'whatsapp', severity: 'warning', check: :consecutive_errors? }
      ].freeze

      def initialize(check_results)
        @checks = check_results.index_by { |item| item[:component] }
      end

      def detect!
        RULES.each do |rule|
          next unless send(rule[:check])

          alert = OptimiaTechnicalAlert.find_or_initialize_by(alert_type: rule[:type], status: 'open')
          next if alert.persisted?

          alert.assign_attributes(
            component: rule[:component],
            severity: rule[:severity],
            message: I18n.t("optimia.technical_health.alerts.#{rule[:type]}", default: rule[:type].humanize),
            opened_at: Time.current
          )
          alert.save!
          IncidentService.new.create_from_alert!(alert)
        end
      end

      private

      def qr_expired?
        OptimiaChannelConnection.lifecycle_active.exists?(['qr_expires_at < ?', Time.current])
      end

      def webhook_broken?
        @checks.dig('webhooks', :status) == 'critical'
      end

      def evolution_down?
        @checks.dig('evolution', :status) == 'critical'
      end

      def redis_down?
        @checks.dig('redis', :status) == 'critical'
      end

      def sidekiq_stopped?
        @checks.dig('sidekiq', :metadata, 'processes').to_i.zero?
      end

      def postgres_slow?
        @checks.dig('postgres', :metadata, 'db_latency_ms').to_i > 500
      end

      def storage_full?
        @checks.dig('storage', :metadata, 'disk_used_percent').to_i >= 90
      end

      def deploy_incomplete?
        @checks.dig('deploy', :metadata, 'pending_migrations') == true
      end

      def excessive_retries?
        @checks.dig('jobs', :metadata, 'retry_size').to_i > 100
      end

      def pending_messages?
        @checks.dig('jobs', :metadata, 'backlog').to_i > 5000
      end

      def consecutive_errors?
        @checks.dig('whatsapp', :metadata, 'with_error').to_i >= 3
      end
    end
  end
end
