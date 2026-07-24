# frozen_string_literal: true

class OptimiaTechnicalTimelineEvent < ApplicationRecord
  belongs_to :optimia_channel_connection, optional: true
  belongs_to :account, optional: true

  validates :component, :event_type, :summary, :occurred_at, presence: true

  scope :recent, -> { order(occurred_at: :desc) }
  scope :for_connection, ->(connection_id) { where(optimia_channel_connection_id: connection_id) }
end
