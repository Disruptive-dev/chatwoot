# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::ConnectionCenterService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:service) { described_class.new(account: account, performed_by: admin) }
  let(:adapter) { instance_double(Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter) }

  before do
    account.enable_features!(:optimia_channel_manager)
    allow(Integrations::Optimia::ChannelManager::ProviderRegistry).to receive(:fetch).and_return(adapter)
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(true)
  end

  describe '#create_connection' do
    it 'creates a draft connection and provisions the instance' do
      allow(adapter).to receive(:ensure_instance!).and_return(
        Integrations::Optimia::ChannelManager::ProviderAdapter::ConnectionResult.new(
          external_instance_id: 'optimia-1-test',
          metadata: { integration: 'WHATSAPP-BAILEYS' },
          credentials: {}
        )
      )
      allow(adapter).to receive(:fetch_qr!).and_return(
        Integrations::Optimia::ChannelManager::ProviderAdapter::QrResult.new(
          base64: 'data:image/png;base64,abc',
          expires_at: 1.minute.from_now,
          pairing_code: nil
        )
      )

      result = service.create_connection(display_name: 'Ventas')

      expect(result[:data][:display_name]).to eq('Ventas')
      expect(result[:data][:state]).to eq('waiting_scan')
      expect(account.optimia_channel_connections.count).to eq(1)
    end
  end

  describe '#refresh_status! provisioning' do
    let(:connection) do
      create(
        :optimia_channel_connection,
        account: account,
        state: 'waiting_scan',
        external_instance_id: 'optimia-1-test',
        phone_number: '+5491112345678'
      )
    end
    let(:webhook_url) { 'https://evo.example.com/chatwoot/webhook/optimia-1-test' }
    let(:sync_service) { instance_double(Optimia::ChannelManager::ChatwootWebhookSyncService) }

    before do
      allow(adapter).to receive(:fetch_status!).and_return(
        Integrations::Optimia::ChannelManager::ProviderAdapter::StatusResult.new(
          remote_state: 'open',
          phone_number: '+5491112345678',
          metadata: {}
        )
      )
      allow(adapter).to receive(:configure_chatwoot!).and_return(success: true, status: 200, data: {})
      allow(Optimia::ChannelManager::ChatwootWebhookSyncService).to receive(:new).and_return(sync_service)
      allow(sync_service).to receive(:perform!).and_return(
        inbox_id: 1,
        webhook_url: webhook_url,
        source: 'derived',
        changed: true
      )
    end

    it 'configures Evolution and syncs the API inbox webhook during ready transition' do
      service.refresh_status!(connection)

      expect(adapter).to have_received(:configure_chatwoot!).with(
        hash_including(
          connection: connection,
          chatwoot_config: hash_including(
            enabled: true,
            accountId: account.id.to_s,
            autoCreate: false,
            number: '5491112345678'
          )
        )
      )
      expect(sync_service).to have_received(:perform!)
      expect(connection.reload.state).to eq('ready')
    end
  end

  describe '#generate_qr!' do
    let(:connection) do
      create(
        :optimia_channel_connection,
        account: account,
        state: 'created',
        external_instance_id: 'optimia-1-test'
      )
    end

    it 'returns qr payload without persisting image' do
      allow(adapter).to receive(:fetch_qr!).and_return(
        Integrations::Optimia::ChannelManager::ProviderAdapter::QrResult.new(
          base64: 'data:image/png;base64,abc',
          expires_at: 1.minute.from_now,
          pairing_code: nil
        )
      )

      result = service.generate_qr!(connection)

      expect(result[:data][:qr][:image_base64]).to eq('data:image/png;base64,abc')
      expect(connection.reload.state).to eq('waiting_scan')
    end
  end
end
