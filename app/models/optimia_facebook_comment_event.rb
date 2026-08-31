# frozen_string_literal: true

class OptimiaFacebookCommentEvent < ApplicationRecord
  STATUSES = %w[received processing answered skipped handoff failed].freeze

  belongs_to :account
  belongs_to :channel_facebook_page, class_name: 'Channel::FacebookPage'
  belongs_to :conversation, optional: true
  has_one :lead, class_name: 'OptimiaFacebookCommentLead',
                 foreign_key: :optimia_facebook_comment_event_id,
                 dependent: :destroy,
                 inverse_of: :comment_event

  validates :idempotency_key, presence: true, uniqueness: true
  validates :correlation_id, :page_id, :comment_id, :status, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :terminal, -> { where(status: %w[answered skipped handoff failed]) }

  def terminal?
    status.in?(STATUSES - %w[received processing])
  end

  def mark_processing!
    update!(status: 'processing') if status == 'received'
  end

  def mark_answered!(response_mode:, response_comment_id: nil, decision: nil)
    update!(
      status: 'answered',
      response_mode: response_mode,
      response_comment_id: response_comment_id,
      decision: decision,
      processed_at: Time.current
    )
  end

  def mark_skipped!(decision:, response_mode: 'none')
    update!(
      status: 'skipped',
      decision: decision,
      response_mode: response_mode,
      processed_at: Time.current
    )
  end

  def mark_handoff!(decision:)
    update!(
      status: 'handoff',
      decision: decision,
      response_mode: 'handoff',
      processed_at: Time.current
    )
  end

  def mark_failed!(error_message:, decision: 'failed')
    update!(
      status: 'failed',
      error_message: error_message.to_s.truncate(500),
      decision: decision,
      processed_at: Time.current
    )
  end
end
