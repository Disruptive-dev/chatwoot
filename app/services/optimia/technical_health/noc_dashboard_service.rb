# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class NocDashboardService
      def self.build
        components = Integrations::Optimia::TechnicalHealth::ComponentCatalog::COMPONENTS.map do |component|
          check = OptimiaTechnicalHealthCheck.latest_for(component)
          {
            component: component,
            status: check&.status || 'unknown',
            checked_at: check&.checked_at,
            latency_ms: check&.latency_ms,
            version: check&.version,
            uptime_seconds: check&.uptime_seconds,
            error_count: check&.error_count || 0
          }
        end

        whatsapp = OptimiaTechnicalHealthCheck.latest_for('whatsapp')&.metadata || {}
        jobs = OptimiaTechnicalHealthCheck.latest_for('jobs')&.metadata || {}
        messages = message_stats

        {
          components: components,
          connections: {
            total: whatsapp['total_connections'].to_i,
            operational: whatsapp['operational'].to_i,
            with_qr: whatsapp['with_qr'].to_i,
            with_error: whatsapp['with_error'].to_i,
            archived: whatsapp['archived'].to_i
          },
          messages: messages,
          jobs: {
            backlog: jobs['backlog'].to_i,
            retry_size: jobs['retry_size'].to_i,
            dead_size: jobs['dead_size'].to_i
          },
          alerts_open: OptimiaTechnicalAlert.open_alerts.count,
          incidents_open: OptimiaTechnicalIncident.where(status: 'open').count
        }
      end

      def self.message_stats
        today = Time.zone.today.all_day
        incoming = Message.incoming.where(created_at: today).count
        outgoing = Message.outgoing.where(created_at: today).count

        {
          today_total: incoming + outgoing,
          inbound: incoming,
          outbound: outgoing
        }
      end
    end
  end
end
