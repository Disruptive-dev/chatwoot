# frozen_string_literal: true

module Optimia
  module ChannelManager
    class ProvisioningService
      def initialize(connection:, performed_by:)
        @connection = connection
        @account = connection.account
        @performed_by = performed_by
      end

      def perform!
        return @connection.inbox if @connection.inbox_id.present? && @connection.inbox.present?

        inbox = find_existing_inbox || create_inbox!
        @connection.update!(inbox: inbox, updated_by: @performed_by)
        inbox
      end

      private

      def find_existing_inbox
        return nil if @connection.inbox_id.blank?

        @account.inboxes.find_by(id: @connection.inbox_id)
      end

      def create_inbox!
        channel = Channel::Api.create!(account: @account)
        Inbox.create!(
          account: @account,
          name: inbox_name,
          channel: channel
        )
      end

      def inbox_name
        base = @connection.display_name.presence || 'WhatsApp'
        suffix = @connection.phone_number.presence
        suffix.present? ? "#{base} (#{suffix})" : "#{base} WhatsApp"
      end
    end
  end
end
