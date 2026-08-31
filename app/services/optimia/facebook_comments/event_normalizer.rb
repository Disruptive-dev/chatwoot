# frozen_string_literal: true

module Optimia
  module FacebookComments
    class EventNormalizer
      SUPPORTED_ITEMS = %w[comment reaction].freeze
      SUPPORTED_VERBS = %w[add edited remove].freeze

      def initialize(payload)
        @payload = payload.deep_symbolize_keys
      end

      def normalize_all
        return [] unless @payload[:object].to_s.casecmp('page').zero?

        Array(@payload[:entry]).flat_map { |entry| normalize_entry(entry) }
      end

      private

      def normalize_entry(entry)
        page_id = entry[:id].to_s
        Array(entry[:changes]).filter_map do |change|
          normalize_change(page_id, change)
        end
      end

      def normalize_change(page_id, change)
        value = (change[:value] || {}).deep_symbolize_keys
        item = value[:item].to_s
        verb = value[:verb].to_s

        return nil unless SUPPORTED_ITEMS.include?(item)
        return nil unless SUPPORTED_VERBS.include?(verb)
        return nil if value[:comment_id].blank? && item == 'comment'

        {
          page_id: page_id,
          post_id: value[:post_id].to_s.presence || extract_post_id(value[:parent_id]),
          comment_id: value[:comment_id].to_s,
          parent_id: value[:parent_id].to_s.presence,
          sender_id: value[:from]&.dig(:id).to_s.presence || value[:sender_id].to_s.presence,
          sender_name: value[:from]&.dig(:name).to_s.presence,
          message: value[:message].to_s,
          created_time: value[:created_time],
          permalink_url: value[:permalink_url].to_s.presence,
          event_type: "#{item}_#{verb}",
          item: item,
          verb: verb,
          raw_value: sanitize_raw_value(value)
        }
      end

      def extract_post_id(parent_id)
        return if parent_id.blank?

        parent_id.to_s.split('_').first(2).join('_').presence
      end

      def sanitize_raw_value(value)
        value.except(:from).merge(from_id: value.dig(:from, :id)).compact
      end
    end
  end
end
