# frozen_string_literal: true

class OptimiaChannelConnectionAudit < ApplicationRecord
  ACTIONS = %w[
    created
    instance_provisioned
    qr_generated
    status_checked
    connected
    provisioning_started
    ready
    disconnected
    reconnected
    error
    disabled
  ].freeze

  belongs_to :optimia_channel_connection
  belongs_to :account
  belongs_to :performed_by, class_name: 'User', optional: true

  validates :action, inclusion: { in: ACTIONS }
end
