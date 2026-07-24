# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Optimia WhatsApp Connections API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:headers) { admin.create_new_auth_token }

  before do
    account.enable_features!(:optimia_channel_manager)
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(true)
  end

  describe 'GET /api/v1/accounts/:account_id/optimia/whatsapp/connections' do
    it 'returns connections for administrators' do
      create(:optimia_channel_connection, account: account, display_name: 'Ventas')

      get "/api/v1/accounts/#{account.id}/optimia/whatsapp/connections", headers: headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].size).to eq(1)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/optimia/whatsapp/connections' do
    it 'creates a connection' do
      adapter = instance_double(Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter)
      allow(Integrations::Optimia::ChannelManager::ProviderRegistry).to receive(:fetch).and_return(adapter)
      allow(adapter).to receive(:ensure_instance!).and_return(
        Integrations::Optimia::ChannelManager::ProviderAdapter::ConnectionResult.new(
          external_instance_id: 'optimia-1-test',
          metadata: {},
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

      post "/api/v1/accounts/#{account.id}/optimia/whatsapp/connections",
           params: { display_name: 'Ventas' },
           headers: headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['data']['display_name']).to eq('Ventas')
    end
  end
end
