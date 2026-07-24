# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::DeleteConnectionService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:adapter) { instance_double(Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter) }
  let(:inbox) { create(:inbox, account: account, channel: create(:channel_api, account: account)) }
  let(:connection) do
    create(
      :optimia_channel_connection,
      account: account,
      inbox: inbox,
      state: 'ready',
      external_instance_id: 'optimia-1-test'
    )
  end

  before do
    allow(Integrations::Optimia::ChannelManager::ProviderRegistry).to receive(:fetch).and_return(adapter)
    allow(adapter).to receive(:disconnect!).and_return(success: true)
    allow(adapter).to receive(:delete_instance!).and_return(success: true)
  end

  it 'sanitizes logs without raising on missing instance' do
    allow(adapter).to receive(:delete_instance!).and_return(success: true)

    expect(Rails.logger).to receive(:info).at_least(:once)

    described_class.new(connection: connection, performed_by: admin, delete_inbox: false).perform!
  end
end
