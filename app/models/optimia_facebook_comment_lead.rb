# frozen_string_literal: true

class OptimiaFacebookCommentLead < ApplicationRecord
  belongs_to :account
  belongs_to :comment_event, class_name: 'OptimiaFacebookCommentEvent',
                             foreign_key: :optimia_facebook_comment_event_id,
                             inverse_of: :lead
  belongs_to :conversation, optional: true

  validates :idempotency_key, presence: true, uniqueness: true
  validates :channel, :source, :page_id, :comment_id, :captured_at, presence: true
end
