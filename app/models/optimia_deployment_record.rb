# frozen_string_literal: true

class OptimiaDeploymentRecord < ApplicationRecord
  validates :version, presence: true

  scope :recent, -> { order(deployed_at: :desc) }
end
