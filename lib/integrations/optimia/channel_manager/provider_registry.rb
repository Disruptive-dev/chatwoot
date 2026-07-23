# frozen_string_literal: true

require_relative 'provider_adapter'

module Integrations
  module Optimia
    module ChannelManager
      class ProviderRegistry
        class << self
          def register(key, adapter_class)
            registry[key.to_s] = adapter_class
          end

          def fetch(key)
            adapter_class = registry[key.to_s]
            raise ArgumentError, "Unknown channel provider: #{key}" if adapter_class.blank?

            adapter_class.new
          end

          def registered?(key)
            registry.key?(key.to_s)
          end

          def keys
            registry.keys
          end

          private

          def registry
            @registry ||= {}
          end
        end
      end
    end
  end
end
