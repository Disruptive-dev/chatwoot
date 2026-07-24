# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      class OutboundDeliveryResult
        attr_reader :http_status, :remote_id, :interpreted

        def initialize(http_status:, remote_id:, interpreted:)
          @http_status = http_status
          @remote_id = remote_id
          @interpreted = interpreted
        end

        def self.extract_remote_id(body)
          return nil unless body.is_a?(Hash)

          body['messageId'] ||
            body['message_id'] ||
            body.dig('key', 'id') ||
            body.dig('data', 'key', 'id') ||
            nested_message_remote_id(body) ||
            body.dig('response', 'key', 'id')
        end

        def self.nested_message_remote_id(body)
          message = body['message']
          return nil unless message.is_a?(Hash)

          message.dig('key', 'id')
        end
      end
    end
  end
end
