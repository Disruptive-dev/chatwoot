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

      result = service.create_connection(display_name: 'Ventas')

      expect(result[:data][:display_name]).to eq('Ventas')
      expect(result[:data][:state]).to eq('created')
      expect(account.optimia_channel_connections.count).to eq(1)
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
