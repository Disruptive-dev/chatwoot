# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class TimelineBuilderService
      EVENT_LABELS = {
        'created' => 'Connection created',
        'connected' => 'Connected',
        'ready' => 'Inbox ready',
        'webhook_synced' => 'Webhook synchronized',
        'qr_generated' => 'QR generated',
        'disconnected' => 'Disconnected',
        'archived' => 'Connection archived',
        'deleted' => 'Connection deleted',
        'health_checked' => 'Health check completed',
        'reconnected' => 'Reconnection started',
        'connection_recovered' => 'Recovery successful'
      }.freeze

      def initialize(connection:)
        @connection = connection
      end

      def build(limit: 50)
        audit_events = audit_timeline(limit)
        platform_events = platform_timeline(limit)
        message_events = recent_message_events

        (audit_events + platform_events + message_events)
          .sort_by { |event| event[:occurred_at] }
          .reverse
          .first(limit)
      end

      private

      def audit_timeline(limit)
        @connection.optimia_channel_connection_audits.order(created_at: :desc).limit(limit).map do |audit|
          {
            occurred_at: audit.created_at,
            component: 'whatsapp',
            event_type: audit.action,
            summary: EVENT_LABELS.fetch(audit.action, audit.action.humanize),
            metadata: Integrations::Optimia::TechnicalHealth::Sanitizer.sanitize(audit.metadata || {})
          }
        end
      end

      def platform_timeline(limit)
        OptimiaTechnicalTimelineEvent.for_connection(@connection.id).recent.limit(limit).map do |event|
          {
            occurred_at: event.occurred_at,
            component: event.component,
            event_type: event.event_type,
            summary: event.summary,
            metadata: event.metadata
          }
        end
      end

      def recent_message_events
        return [] unless @connection.inbox_id

        Message.where(inbox_id: @connection.inbox_id)
               .where(message_type: %i[incoming outgoing])
               .order(created_at: :desc)
               .limit(10)
               .map do |message|
          {
            occurred_at: message.created_at,
            component: 'whatsapp',
            event_type: message.incoming? ? 'message_received' : 'message_sent',
            summary: message.incoming? ? 'Message received' : 'Message sent',
            metadata: { status: message.status, message_id: message.id }
          }
        end
      end
    end
  end
end
