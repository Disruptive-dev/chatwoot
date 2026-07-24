# frozen_string_literal: true

class OptimiaTechnicalAlert < ApplicationRecord
  validates :alert_type, :component, :severity, :status, :opened_at, presence: true

  scope :recent, -> { order(opened_at: :desc) }
  scope :open_alerts, -> { where(status: 'open') }

  def duration_seconds
    end_time = resolved_at || Time.current
    (end_time - opened_at).to_i
  end
end
