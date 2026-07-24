# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      class ChatwootWebhookResolver
        WEBHOOK_URL_KEYS = %w[webhook_url webhookUrl].freeze

        def initialize(client: Integrations::Evolution::Client.new)
          @client = client
        end

        def resolve(instance_name:)
          find_result = @client.find_chatwoot(instance_name)
          webhook_url = extract_webhook_url(find_result[:data]) if find_result[:error].blank?

          if webhook_url.present?
            return {
              webhook_url: webhook_url,
              source: 'evolution_find',
              http_status: find_result[:status]
            }
          end

          derived_url = Integrations::Evolution::Client.chatwoot_webhook_url_for(instance_name)
          raise ArgumentError, 'Unable to derive Evolution Chatwoot webhook URL' if derived_url.blank?

          {
            webhook_url: derived_url,
            source: 'derived',
            http_status: find_result[:status]
          }
        end

        private

        def extract_webhook_url(payload)
          return nil if payload.blank?

          case payload
          when Hash
            WEBHOOK_URL_KEYS.each do |key|
              value = payload[key] || payload[key.to_sym]
              return value if value.present?
            end

            payload.values.lazy.map { |value| extract_webhook_url(value) }.find(&:present?)
          when Array
            payload.lazy.map { |item| extract_webhook_url(item) }.find(&:present?)
          end
        end
      end
    end
  end
end
