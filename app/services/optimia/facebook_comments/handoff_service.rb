# frozen_string_literal: true

module Optimia
  module FacebookComments
    class HandoffService
      def initialize(account:, inbox:, comment_event:, conversation: nil)
        @account = account
        @inbox = inbox
        @comment_event = comment_event
        @conversation = conversation
      end

      def perform
        conversation = @conversation || find_or_create_conversation
        pause_automation!(conversation)
        conversation.bot_handoff! if conversation.pending?
        conversation.update!(status: :open) unless conversation.open?
        conversation
      end

      private

      def find_or_create_conversation
        contact_inbox = find_or_create_contact_inbox
        existing = Conversation.where(
          account_id: @account.id,
          inbox_id: @inbox.id,
          contact_id: contact_inbox.contact_id
        ).where.not(status: :resolved).order(created_at: :desc).first

        existing || Conversation.create!(
          account: @account,
          inbox: @inbox,
          contact: contact_inbox.contact,
          contact_inbox: contact_inbox,
          additional_attributes: {
            'optimia_facebook_comment_handoff' => true,
            'facebook_comment_id' => @comment_event.comment_id
          }
        )
      end

      def find_or_create_contact_inbox
        ::ContactInboxWithContactBuilder.new(
          source_id: @comment_event.sender_id,
          inbox: @inbox,
          contact_attributes: { name: 'Facebook Comment User' }
        ).perform
      end

      def pause_automation!(conversation)
        conversation.update!(
          additional_attributes: conversation.additional_attributes.merge(
            'optimia_facebook_comment_automation_paused' => true
          )
        )
      end
    end
  end
end
