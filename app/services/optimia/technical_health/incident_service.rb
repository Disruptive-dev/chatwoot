# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class IncidentService
      def create_from_alert!(alert)
        return if OptimiaTechnicalIncident.exists?(component: alert.component, status: 'open')

        OptimiaTechnicalIncident.create!(
          component: alert.component,
          status: 'open',
          summary: alert.message,
          started_at: alert.opened_at,
          detected_at: Time.current,
          metadata: { alert_id: alert.id, alert_type: alert.alert_type }
        )
      end

      def acknowledge!(incident:, responsible: nil)
        incident.update!(
          status: 'acknowledged',
          acknowledged_at: Time.current,
          responsible: responsible
        )
      end

      def resolve!(incident:, root_cause: nil, action_taken: nil, responsible: nil)
        incident.update!(
          status: 'resolved',
          resolved_at: Time.current,
          root_cause: root_cause,
          action_taken: action_taken,
          responsible: responsible,
          duration_seconds: incident.duration_seconds
        )
      end
    end
  end
end
