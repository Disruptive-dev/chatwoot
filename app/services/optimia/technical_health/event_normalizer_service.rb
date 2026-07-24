# frozen_string_literal: true

module Optimia
  module TechnicalHealth
    class EventNormalizerService
      EVENT_LABELS = {
        'webhook_rejected' => 'Webhook rejected',
        'evolution_unauthorized' => 'Evolution returned 401',
        'redis_unavailable' => 'Redis without response',
        'retry_executed' => 'Retry executed',
        'inbox_restored' => 'Inbox restored',
        'reconnection_successful' => 'Reconnection successful'
      }.freeze

      def self.record!(component:, event_type:, summary: nil, connection: nil, account: nil, metadata: {}, occurred_at: Time.current)
        new.record!(
          component: component,
          event_type: event_type,
          summary: summary,
          connection: connection,
          account: account,
          metadata: metadata,
          occurred_at: occurred_at
        )
      end

      def record!(component:, event_type:, summary: nil, connection: nil, account: nil, metadata: {}, occurred_at: Time.current)
        OptimiaTechnicalTimelineEvent.create!(
          optimia_channel_connection: connection,
          account: account || connection&.account,
          component: component,
          event_type: event_type,
          summary: summary || EVENT_LABELS.fetch(event_type, event_type.humanize),
          metadata: Integrations::Optimia::TechnicalHealth::Sanitizer.sanitize(metadata),
          occurred_at: occurred_at
        )
      end
    end
  end
end
