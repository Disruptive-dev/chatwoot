# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class MetricsCollectorService
      def record_from_checks!(checks)
        indexed = checks.index_by { |item| item[:component] }
        whatsapp = indexed['whatsapp']&.dig(:metadata) || {}
        jobs = indexed['jobs']&.dig(:metadata) || {}

        OptimiaTechnicalMetricSnapshot.create!(
          recorded_at: Time.current,
          metrics: {
            uptime_seconds: indexed['rails']&.dig(:uptime_seconds),
            sidekiq_latency_ms: indexed.dig('sidekiq', :metadata, 'sidekiq_latency_ms'),
            redis_latency_ms: indexed.dig('redis', :metadata, 'redis_latency_ms'),
            db_latency_ms: indexed.dig('postgres', :metadata, 'db_latency_ms'),
            evolution_latency_ms: indexed.dig('evolution', :metadata, 'evolution_latency_ms'),
            messages_sent_today: NocDashboardService.message_stats[:outbound],
            messages_received_today: NocDashboardService.message_stats[:inbound],
            callbacks_today: 0,
            errors: whatsapp['with_error'].to_i,
            retries: jobs['retry_size'].to_i,
            reconnections: 0,
            qr_generated: whatsapp['with_qr'].to_i
          }
        )
      end
    end
  end
end
