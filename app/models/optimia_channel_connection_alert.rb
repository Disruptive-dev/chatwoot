# frozen_string_literal: true

class OptimiaChannelConnectionAlert < ApplicationRecord
  ALERT_TYPES = %w[
    disconnected
    reconnect_started
    reconnect_succeeded
    qr_required
    evolution_unavailable
    webhook_missing
    inbox_inconsistent
    consecutive_failures
  ].freeze

  belongs_to :optimia_channel_connection
  belongs_to :account

  validates :alert_type, inclusion: { in: ALERT_TYPES }
  validates :message, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
