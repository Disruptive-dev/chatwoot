# frozen_string_literal: true

class OptimiaTechnicalMetricSnapshot < ApplicationRecord
  validates :recorded_at, presence: true

  scope :recent, -> { order(recorded_at: :desc) }
end
