# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::Accounts::Optimia::Whatsapp::Connections lifecycle', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:connection) do
    create(
      :optimia_channel_connection,
      account: account,
      state: 'ready',
      external_instance_id: 'optimia-1-test'
    )
  end

  before do
    account.enable_features!(:optimia_channel_manager)
    allow(Integrations::Optimia::ChannelManager::ProviderRegistry).to receive(:fetch).and_return(
      instance_double(
        Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter,
        disconnect!: { success: true },
        delete_instance!: { success: true }
      )
    )
  end

  describe 'POST /deactivate' do
    it 'allows administrators' do
      post deactivate_api_v1_account_optimia_whatsapp_connection_path(account, connection),
           headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(connection.reload.lifecycle_status).to eq('archived')
    end

    it 'denies agents' do
      post deactivate_api_v1_account_optimia_whatsapp_connection_path(account, connection),
           headers: agent.create_new_auth_token

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'DELETE /connections/:id' do
    it 'marks connection deleted' do
      delete api_v1_account_optimia_whatsapp_connection_path(account, connection),
             params: { delete_inbox: false },
             headers: admin.create_new_auth_token

      expect(response).to have_http_status(:success)
      expect(connection.reload.lifecycle_status).to eq('deleted')
    end
  end
end
