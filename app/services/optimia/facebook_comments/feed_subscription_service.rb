# frozen_string_literal: true

module Optimia
  module FacebookComments
    class FeedSubscriptionService
      def initialize(channel:)
        @channel = channel
      end

      def perform
        return unless Integrations::Optimia::FacebookComments::Feature.comments_enabled_for_account?(@channel.account)

        client = GraphApiClient.new(access_token: @channel.page_access_token)
        response = client.subscribe_feed!
        Rails.logger.info({
          event: 'optimia_facebook_feed_subscribed',
          account_id: @channel.account_id,
          page_id: @channel.page_id,
          success: response.success?
        }.to_json)
        response.success?
      end
    end
  end
end
