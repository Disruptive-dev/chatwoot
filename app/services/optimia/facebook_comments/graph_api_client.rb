# frozen_string_literal: true

module Optimia
  module FacebookComments
    class GraphApiClient
      include Facebook::GraphApiSupport

      def initialize(access_token:)
        @access_token = access_token
        @api = koala_api(access_token)
      end

      def reply_to_comment(comment_id:, message:)
        @api.put_comment(comment_id, message)
      end

      def private_reply_to_comment(comment_id:, message:)
        version = api_version
        response = HTTParty.post(
          "https://graph.facebook.com/#{version}/#{comment_id}/private_replies",
          body: { message: message, access_token: @access_token }
        )
        parse_response(response)
      end

      def subscribe_feed!
        version = api_version
        page_id = @api.get_object('me', fields: 'id')['id']
        HTTParty.post(
          "https://graph.facebook.com/#{version}/#{page_id}/subscribed_apps",
          query: {
            subscribed_fields: self.class.feed_subscribed_fields.join(','),
            access_token: @access_token
          }
        )
      end

      def self.feed_subscribed_fields
        %w[feed]
      end

      def self.messenger_subscribed_fields
        %w[messages message_deliveries message_echoes message_reads standby messaging_handovers]
      end

      private

      def parse_response(response)
        parsed = response.parsed_response
        if response.success?
          parsed.is_a?(Hash) ? parsed : { 'success' => true }
        else
          error_message = parsed.is_a?(Hash) ? (parsed.dig('error', 'message') || parsed['error']) : response.message
          raise StandardError, error_message.to_s
        end
      end
    end
  end
end
