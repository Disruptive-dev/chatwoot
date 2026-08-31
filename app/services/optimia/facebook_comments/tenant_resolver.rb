# frozen_string_literal: true

module Optimia
  module FacebookComments
    class TenantResolver
      Result = Struct.new(:channel, :account, :inbox, keyword_init: true) do
        def resolved?
          channel.present? && account.present? && inbox.present?
        end
      end

      def initialize(page_id:)
        @page_id = page_id.to_s
      end

      def resolve
        channels = Channel::FacebookPage.includes(:account).where(page_id: @page_id)
        return Result.new unless channels.one?

        channel = channels.first
        inbox = Inbox.find_by(channel: channel)
        Result.new(channel: channel, account: channel.account, inbox: inbox)
      end
    end
  end
end
