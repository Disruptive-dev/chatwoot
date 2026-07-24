# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Optimia::ChannelManager::ChatwootWebhookResolver do
  let(:client) { instance_double(Integrations::Evolution::Client) }
  let(:resolver) { described_class.new(client: client) }

  before do
    allow(Integrations::Evolution::Client).to receive(:chatwoot_webhook_url_for)
      .with('optimia-1-test')
      .and_return('https://evo.example.com/chatwoot/webhook/optimia-1-test')
  end

  describe '#resolve' do
    it 'returns webhook_url from Evolution find when available' do
      allow(client).to receive(:find_chatwoot).with('optimia-1-test').and_return(
        data: { 'webhook_url' => 'https://evo.example.com/chatwoot/webhook/optimia-1-test' },
        status: 200
      )

      result = resolver.resolve(instance_name: 'optimia-1-test')

      expect(result[:webhook_url]).to eq('https://evo.example.com/chatwoot/webhook/optimia-1-test')
      expect(result[:source]).to eq('evolution_find')
    end

    it 'falls back to derived webhook_url when find has no webhook_url' do
      allow(client).to receive(:find_chatwoot).with('optimia-1-test').and_return(
        data: { 'enabled' => true },
        status: 200
      )

      result = resolver.resolve(instance_name: 'optimia-1-test')

      expect(result[:webhook_url]).to eq('https://evo.example.com/chatwoot/webhook/optimia-1-test')
      expect(result[:source]).to eq('derived')
    end
  end
end
