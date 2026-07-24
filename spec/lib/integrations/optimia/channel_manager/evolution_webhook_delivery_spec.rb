# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Optimia::ChannelManager::EvolutionWebhookDelivery do
  let(:account) { create(:account) }
  let(:webhook_url) { 'https://evo.example.com/chatwoot/webhook/optimia-1-test' }
  let(:channel) { create(:channel_api, account: account, webhook_url: webhook_url) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:connection) do
    create(
      :optimia_channel_connection,
      account: account,
      inbox: inbox,
      provider: 'evolution',
      external_instance_id: 'optimia-1-test'
    )
  end
  let(:message) do
    create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: :outgoing,
      content: 'Hola sin firma',
      status: :sent
    )
  end
  let(:payload) do
    {
      event: 'message_created',
      id: message.id,
      content: message.content,
      message_type: 'outgoing'
    }
  end

  before do
    allow(GlobalConfig).to receive(:get_value).and_call_original
    allow(GlobalConfig).to receive(:get_value).with('OPTIMIA_EVOLUTION_WEBHOOK_TIMEOUT').and_return('30')
  end

  describe '.evolution_webhook?' do
    it 'detects evolution chatwoot webhook urls' do
      expect(described_class.evolution_webhook?(webhook_url)).to be(true)
      expect(described_class.evolution_webhook?('https://other.example.com/hook')).to be(false)
    end
  end

  describe '#execute' do
    it 'keeps message sent on successful evolution acknowledgement without agent signature changes' do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: { message: 'bot' }.to_json, headers: { 'Content-Type' => 'application/json' })

      described_class.execute(webhook_url, payload)

      expect(message.reload.status).to eq('sent')
      expect(message.content).to eq('Hola sin firma')
    end

    it 'persists remote id from evolution success variants' do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: { key: { id: 'EVO-MSG-1' } }.to_json, headers: { 'Content-Type' => 'application/json' })

      described_class.execute(webhook_url, payload)

      expect(message.reload.source_id).to eq('EVO-MSG-1')
      expect(message.status).to eq('sent')
    end

    it 'persists messageId variant from evolution 2.3.7 style payloads' do
      stub_request(:post, webhook_url)
        .to_return(status: 200, body: { messageId: 'EVO-MSG-2' }.to_json, headers: { 'Content-Type' => 'application/json' })

      described_class.execute(webhook_url, payload)

      expect(message.reload.source_id).to eq('EVO-MSG-2')
    end

    it 'does not mark failed on read timeout after evolution may have accepted the message' do
      stub_request(:post, webhook_url).to_timeout

      described_class.execute(webhook_url, payload)

      expect(message.reload.status).to eq('sent')
    end

    it 'marks failed on connection refused' do
      stub_request(:post, webhook_url).to_raise(Errno::ECONNREFUSED)

      described_class.execute(webhook_url, payload)

      expect(message.reload.status).to eq('failed')
      expect(message.external_error).to be_present
    end

    it 'marks failed on client error responses' do
      stub_request(:post, webhook_url)
        .to_return(status: 422, body: { message: 'invalid payload' }.to_json, headers: { 'Content-Type' => 'application/json' })

      described_class.execute(webhook_url, payload)

      expect(message.reload.status).to eq('failed')
    end

    it 'does not mark failed on server error responses' do
      stub_request(:post, webhook_url)
        .to_return(status: 500, body: { message: 'temporary error' }.to_json, headers: { 'Content-Type' => 'application/json' })

      described_class.execute(webhook_url, payload)

      expect(message.reload.status).to eq('sent')
    end
  end
end
