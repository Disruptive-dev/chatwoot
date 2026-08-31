# frozen_string_literal: true

module Optimia
  module FacebookComments
    class PropertyContextResolver
      def initialize(account:, page_id:, post_id:)
        @account = account
        @page_id = page_id.to_s
        @post_id = post_id.to_s
      end

      def resolve
        mapping = OptimiaFacebookPostProperty.find_by(account: @account, post_id: @post_id)
        return build_from_mapping(mapping) if mapping.present?

        PropertyContext.new(
          property_id: nil,
          post_id: @post_id,
          source: 'unmapped',
          confidence: 0.0,
          known_facts: {}
        )
      end

      private

      def build_from_mapping(mapping)
        PropertyContext.new(
          property_id: mapping.property_id,
          post_id: mapping.post_id,
          source: mapping.source,
          confidence: mapping.confidence,
          known_facts: mapping.known_facts_hash
        )
      end
    end
  end
end
