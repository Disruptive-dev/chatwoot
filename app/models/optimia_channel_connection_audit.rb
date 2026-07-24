# frozen_string_literal: true

class OptimiaChannelConnectionAudit < ApplicationRecord
  ACTIONS = %w[
    created
    instance_provisioned
    qr_generated
    status_checked
    health_checked
    state_changed
    connected
    provisioning_started
    ready
    disconnected
    reconnected
    reconnect_started
    reconnect_succeeded
    reconnect_failed
    qr_required
    qr_refreshed
    webhook_synced
    webhook_sync_failed
    connection_degraded
    connection_recovered
    error
    disabled
  ].freeze

  belongs_to :optimia_channel_connection
  belongs_to :account
  belongs_to :performed_by, class_name: 'User', optional: true

  validates :action, inclusion: { in: ACTIONS }
end
