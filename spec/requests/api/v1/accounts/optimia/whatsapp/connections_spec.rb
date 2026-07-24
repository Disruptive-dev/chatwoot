# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Optimia WhatsApp Connections API', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:admin_headers) { admin.create_new_auth_token }
  let(:agent_headers) { agent.create_new_auth_token }
  let(:connections_path) { "/api/v1/accounts/#{account.id}/optimia/whatsapp/connections" }

  before do
    account.enable_features!(:optimia_channel_manager)
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(true)
  end

  describe 'GET /api/v1/accounts/:account_id/optimia/whatsapp/connections' do
    it 'returns connections for administrators' do
      create(:optimia_channel_connection, account: account, display_name: 'Ventas')

      get connections_path, headers: admin_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['data'].size).to eq(1)
    end

    it 'returns unauthorized for unauthenticated users' do
      get connections_path

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized for account agents' do
      get connections_path, headers: agent_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('You are not authorized to do this action')
    end

    it 'returns unauthorized for administrators of another account' do
      other_account = create(:account)
      other_admin = create(:user, account: other_account, role: :administrator)

      get connections_path, headers: other_admin.create_new_auth_token

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('You are not authorized to access this account')
    end

    it 'returns forbidden when the feature flag is disabled' do
      account.disable_features!(:optimia_channel_manager)

      get connections_path, headers: admin_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error_code']).to eq('feature_disabled')
    end
  end

  describe 'POST /api/v1/accounts/:account_id/optimia/whatsapp/connections' do
    let(:adapter) { instance_double(Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter) }

    before do
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
    end

    it 'creates a connection for administrators' do
      post connections_path,
           params: { display_name: 'Ventas' },
           headers: admin_headers

      expect(response).to have_http_status(:created)
      expect(response.parsed_body['data']['display_name']).to eq('Ventas')
    end

    it 'returns unauthorized for unauthenticated users' do
      post connections_path, params: { display_name: 'Ventas' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized for account agents' do
      post connections_path,
           params: { display_name: 'Ventas' },
           headers: agent_headers

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('You are not authorized to do this action')
    end

    it 'returns unauthorized for administrators of another account' do
      other_account = create(:account)
      other_admin = create(:user, account: other_account, role: :administrator)

      post connections_path,
           params: { display_name: 'Ventas' },
           headers: other_admin.create_new_auth_token

      expect(response).to have_http_status(:unauthorized)
      expect(response.parsed_body['error']).to eq('You are not authorized to access this account')
    end

    it 'returns forbidden when the feature flag is disabled' do
      account.disable_features!(:optimia_channel_manager)

      post connections_path,
           params: { display_name: 'Ventas' },
           headers: admin_headers

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body['error_code']).to eq('feature_disabled')
    end
  end
end
