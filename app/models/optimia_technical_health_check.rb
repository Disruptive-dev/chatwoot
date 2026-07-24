# frozen_string_literal: true

class OptimiaTechnicalHealthCheck < ApplicationRecord
  STATUSES = Integrations::Optimia::TechnicalHealth::ComponentCatalog::STATUSES

  validates :component, :status, :checked_at, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :recent, -> { order(checked_at: :desc) }

  def self.latest_for(component)
    where(component: component).order(checked_at: :desc).first
  end

  def self.latest_by_component
    recent.group_by(&:component).transform_values(&:first)
  end
end
