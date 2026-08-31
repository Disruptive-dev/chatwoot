# frozen_string_literal: true

module Optimia
  module FacebookComments
    PropertyContext = Struct.new(:property_id, :post_id, :source, :confidence, :known_facts, keyword_init: true) do
      def present?
        property_id.present?
      end

      def fact(key)
        known_facts[key.to_s] || known_facts[key.to_sym]
      end

      def to_h
        {
          property_id: property_id,
          post_id: post_id,
          source: source,
          confidence: confidence,
          known_facts: known_facts || {}
        }
      end
    end
  end
end
