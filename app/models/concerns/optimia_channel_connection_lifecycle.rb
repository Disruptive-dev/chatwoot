# frozen_string_literal: true

module OptimiaChannelConnectionLifecycle
  extend ActiveSupport::Concern

  LIFECYCLE_STATUSES = %w[
    active
    inactive
    disconnected
    archived
    deleting
    deleted
    error
  ].freeze

  LIFECYCLE_TERMINAL_STATUSES = %w[deleted].freeze
  LIFECYCLE_NON_MONITORABLE_STATUSES = %w[inactive archived deleting deleted error].freeze
  LIFECYCLE_NON_RECREATABLE_STATUSES = %w[inactive archived deleting deleted error].freeze

  included do
    validates :lifecycle_status, inclusion: { in: LIFECYCLE_STATUSES }

    scope :lifecycle_active, -> { where(lifecycle_status: 'active') }
    scope :recreatable, -> { lifecycle_active.where(inbox_recreation_enabled: true) }
    scope :administratively_visible, -> { where.not(lifecycle_status: 'deleted') }
  end

  def lifecycle_active?
    lifecycle_status == 'active'
  end

  def lifecycle_archived?
    lifecycle_status.in?(%w[archived inactive])
  end

  def lifecycle_deleting?
    lifecycle_status == 'deleting'
  end

  def lifecycle_deleted?
    lifecycle_status == 'deleted'
  end

  def lifecycle_terminal?
    LIFECYCLE_TERMINAL_STATUSES.include?(lifecycle_status)
  end

  def monitorable_lifecycle?
    lifecycle_active? && !lifecycle_deleting?
  end

  def inbox_recreation_allowed?
    lifecycle_active? && inbox_recreation_enabled? && !lifecycle_deleting?
  end

  def provisioning_allowed?
    inbox_recreation_allowed?
  end

  def restoration_allowed?
    lifecycle_status.in?(%w[archived inactive])
  end
end
