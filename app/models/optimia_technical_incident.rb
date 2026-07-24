# frozen_string_literal: true

class OptimiaTechnicalIncident < ApplicationRecord
  validates :component, :status, :started_at, presence: true

  scope :recent, -> { order(started_at: :desc) }

  def duration_seconds
    end_time = resolved_at || Time.current
    (end_time - started_at).to_i
  end
end
