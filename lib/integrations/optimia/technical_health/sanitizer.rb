# frozen_string_literal: true

module Integrations
  module Optimia
    module TechnicalHealth
      module Sanitizer
        SENSITIVE_KEYS = %w[
          token api_key apikey password secret credential authorization
          phone_number number qr pairing_code webhook_url
        ].freeze

        module_function

        def sanitize(value)
          case value
          when Hash
            value.each_with_object({}) do |(key, nested), result|
              next if sensitive_key?(key)

              result[key] = sanitize(nested)
            end
          when Array
            value.map { |item| sanitize(item) }
          else
            value
          end
        end

        def sensitive_key?(key)
          SENSITIVE_KEYS.any? { |fragment| key.to_s.downcase.include?(fragment) }
        end
      end
    end
  end
end
