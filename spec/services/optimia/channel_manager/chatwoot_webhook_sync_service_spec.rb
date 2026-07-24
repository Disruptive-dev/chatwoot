# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::ChatwootWebhookSyncService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:channel) { create(:channel_api, account: account, webhook_url: nil) }
  let(:inbox) { channel.inbox }
  let(:connection) do
    create(
      :optimia_channel_connection,
      account: account,
      inbox: inbox,
      state: 'syncing',
      external_instance_id: 'optimia-1-test',
      phone_number: '+5491112345678'
    )
  end
  let(:resolver) { instance_double(Integrations::Optimia::ChannelManager::ChatwootWebhookResolver) }
  let(:service) { described_class.new(connection: connection, performed_by: admin, resolver: resolver) }
  let(:webhook_url) { 'https://evo.example.com/chatwoot/webhook/optimia-1-test' }

  before do
    allow(resolver).to receive(:resolve).and_return(
      webhook_url: webhook_url,
      source: 'derived',
      http_status: 200
    )
  end

  describe '#perform!' do
    it 'stores Evolution webhook_url on the API channel' do
      result = service.perform!

      expect(channel.reload.webhook_url).to eq(webhook_url)
      expect(result[:changed]).to be(true)
      expect(connection.reload.connection_metadata['evolution_webhook_url']).to eq(webhook_url)
    end

    it 'is idempotent when webhook_url is already configured' do
      channel.update!(webhook_url: webhook_url)

      result = service.perform!

      expect(result[:changed]).to be(false)
      expect(channel.reload.webhook_url).to eq(webhook_url)
    end

    it 'rejects cross-account inbox mismatches' do
      other_account = create(:account)
      other_channel = create(:channel_api, account: other_account)
      connection.update!(inbox: other_channel.inbox)

      expect { service.perform! }.to raise_error(
        Optimia::ChannelManager::ChatwootWebhookSyncService::SyncError,
        'Cross-account inbox mismatch'
      )
    end

    it 'rejects connections that are not ready for sync' do
      connection.update!(state: 'draft')

      expect { service.perform! }.to raise_error(
        Optimia::ChannelManager::ChatwootWebhookSyncService::SyncError,
        'Connection is not ready for webhook sync'
      )
    end
  end

  describe '.diagnose' do
    it 'reports whether outbound wiring is ready without exposing secrets' do
      channel.update!(webhook_url: webhook_url)
      connection.update!(state: 'ready', connection_metadata: {
                           'evolution_webhook_url' => webhook_url,
                           'evolution_webhook_source' => 'derived',
                           'webhook_synced_at' => Time.current.iso8601
                         })

      diagnosis = described_class.diagnose(connection: connection.reload)

      expect(diagnosis[:connection_id]).to eq(connection.id)
      expect(diagnosis[:webhook_url_configured]).to be(true)
      expect(diagnosis[:webhook_url_host]).to eq('evo.example.com')
      expect(diagnosis[:ready_for_outbound]).to be(true)
      expect(diagnosis).not_to include(:token)
    end
  end
end
