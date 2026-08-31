# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::FacebookComments::Processor do
  let!(:channel) do
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe)
    create(:channel_facebook_page, page_id: 'page_123')
  end
  let(:account) { channel.account }
  let(:inbox) { channel.inbox }

  let(:normalized_event) do
    {
      page_id: 'page_123',
      post_id: 'page_123_post_1',
      comment_id: 'comment_abc',
      parent_id: nil,
      sender_id: 'user_999',
      message: message_text,
      event_type: 'comment_add',
      item: 'comment',
      verb: 'add',
      raw_value: {}
    }
  end

  before do
    Integrations::Optimia::FacebookComments::Feature.enable_for_account!(account)
    allow(Optimia::FacebookComments::PublicReplyService).to receive(:new).and_return(
      instance_double(Optimia::FacebookComments::PublicReplyService, perform: 'reply_1')
    )
    allow(Optimia::FacebookComments::PrivateReplyService).to receive(:new).and_return(
      instance_double(Optimia::FacebookComments::PrivateReplyService, perform: 'private_1')
    )
  end

  def process!
    described_class.new(normalized_event: normalized_event).perform
  end

  context 'when message is "Precio?" with known price' do
    let(:message_text) { 'Precio?' }

    before do
      create(:optimia_facebook_post_property,
             account: account,
             page_id: 'page_123',
             post_id: 'page_123_post_1',
             known_facts: { 'price' => 'USD 150.000' })
    end

    it 'replies publicly with official price and no duplicate on retry' do
      expect { process! }.to change(OptimiaFacebookCommentEvent, :count).by(1)
      event = OptimiaFacebookCommentEvent.last
      expect(event.status).to eq('answered')
      expect(event.response_mode).to eq('public')

      expect(Optimia::FacebookComments::PublicReplyService).to have_received(:new).once

      expect { process! }.not_to change(OptimiaFacebookCommentEvent, :count)
      expect(Optimia::FacebookComments::PublicReplyService).to have_received(:new).once
    end
  end

  context 'when message is "Me interesa"' do
    let(:message_text) { 'Me interesa' }

    it 'captures lead and replies publicly' do
      process!
      event = OptimiaFacebookCommentEvent.last
      expect(event.intent).to eq('interest')
      expect(event.lead).to be_present
      expect(event.status).to eq('answered')
    end
  end

  context 'when message is irrelevant emoji' do
    let(:message_text) { '👍' }

    it 'skips without reply' do
      process!
      expect(OptimiaFacebookCommentEvent.last.status).to eq('skipped')
      expect(Optimia::FacebookComments::PublicReplyService).not_to have_received(:new)
    end
  end

  context 'when tenant feature is disabled' do
    let(:message_text) { 'Precio?' }

    before { Integrations::Optimia::FacebookComments::Feature.disable_for_account!(account) }

    it 'does not create events' do
      expect { process! }.not_to change(OptimiaFacebookCommentEvent, :count)
    end
  end

  context 'when page is unknown' do
    let(:message_text) { 'Precio?' }

    before { normalized_event[:page_id] = 'unknown_page' }

    it 'skips processing' do
      expect { process! }.not_to change(OptimiaFacebookCommentEvent, :count)
    end
  end

  context 'when multiple tenants share page_id' do
    let(:message_text) { 'Precio?' }

    before do
      other_account = create(:account)
      other_inbox = create(:inbox, account: other_account)
      create(:channel_facebook_page, account: other_account, page_id: 'page_123', inbox: other_inbox)
    end

    it 'does not process to avoid cross-tenant routing' do
      expect { process! }.not_to change(OptimiaFacebookCommentEvent, :count)
    end
  end

  context 'when handoff is requested' do
    let(:message_text) { 'Quiero hablar con un asesor' }

    it 'marks handoff and captures lead' do
      process!
      event = OptimiaFacebookCommentEvent.last
      expect(event.status).to eq('answered')
      expect(event.decision).to eq('handoff')
      expect(event.lead.intent).to eq('handoff')
    end
  end

  context 'when personal data is shared' do
    let(:message_text) { 'Mi teléfono es +5491112345678' }

    it 'uses private reply mode' do
      process!
      event = OptimiaFacebookCommentEvent.last
      expect(event.response_mode).to eq('private')
      expect(Optimia::FacebookComments::PrivateReplyService).to have_received(:new)
    end
  end

  context 'when property is unknown' do
    let(:message_text) { 'Precio?' }

    it 'does not invent price' do
      generator = instance_double(Optimia::FacebookComments::AiReplyGenerator, generate: 'safe reply')
      allow(Optimia::FacebookComments::AiReplyGenerator).to receive(:new).and_return(generator)
      process!
      expect(generator).to have_received(:generate)
    end
  end

  context 'when Meta API fails' do
    let(:message_text) { 'Info' }

    before do
      allow(Optimia::FacebookComments::PublicReplyService).to receive(:new).and_return(
        instance_double(Optimia::FacebookComments::PublicReplyService).tap do |svc|
          allow(svc).to receive(:perform).and_raise(StandardError, 'Graph API error')
        end
      )
    end

    it 'marks event as failed' do
      expect { process! }.to raise_error(StandardError)
      expect(OptimiaFacebookCommentEvent.last.status).to eq('failed')
    end
  end

  context 'when handoff is already active' do
    let(:message_text) { 'Precio?' }

    before do
      contact_inbox = ContactInboxWithContactBuilder.new(
        source_id: 'user_999',
        inbox: inbox,
        contact_attributes: { name: 'FB User' }
      ).perform
      create(:conversation,
             account: account,
             inbox: inbox,
             contact: contact_inbox.contact,
             contact_inbox: contact_inbox,
             status: :open,
             additional_attributes: { 'optimia_facebook_comment_automation_paused' => true })
    end

    it 'skips automated reply' do
      process!
      expect(OptimiaFacebookCommentEvent.last.status).to eq('skipped')
      expect(Optimia::FacebookComments::PublicReplyService).not_to have_received(:new)
    end
  end
end
