# frozen_string_literal: true

module Optimia
  module FacebookComments
    class PublicReplyService
      def initialize(channel:)
        @channel = channel
        @client = GraphApiClient.new(access_token: channel.page_access_token)
      end

      def perform(comment_id:, message:)
        result = @client.reply_to_comment(comment_id: comment_id, message: message)
        result['id'] || result[:id]
      end
    end
  end
end
