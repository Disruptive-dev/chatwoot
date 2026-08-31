# frozen_string_literal: true

class Webhooks::FacebookPageEventsJob < ApplicationJob
  queue_as :default
  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(payload)
    correlation_id = SecureRandom.uuid
    normalized_events = Optimia::FacebookComments::EventNormalizer.new(payload).normalize_all

    normalized_events.each do |event|
      next unless event[:verb] == 'add'
      next if event[:item] == 'comment' && page_comment_from_page?(event)

      Optimia::FacebookComments::Processor.new(
        normalized_event: event,
        correlation_id: correlation_id
      ).perform
    end
  end

  private

  def page_comment_from_page?(event)
    event[:sender_id].present? && event[:sender_id] == event[:page_id]
  end
end
