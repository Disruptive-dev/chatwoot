# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::MonitorConnectionsJob do
  let(:account) { create(:account) }
  let!(:connection) do
    create(
      :optimia_channel_connection,
      account: account,
      state: 'ready',
      external_instance_id: 'optimia-1-test'
    )
  end

  before do
    account.enable_features!(:optimia_channel_manager)
    allow(Integrations::Optimia::ChannelManager::Feature).to receive(:globally_enabled?).and_return(true)
    allow(Integrations::Optimia::ChannelManager::MonitorConfig).to receive(:monitoring_enabled?).and_return(true)
    allow(Optimia::ChannelManager::HealthMonitorService).to receive(:new).and_return(
      instance_double(Optimia::ChannelManager::HealthMonitorService, perform!: { status: 'checked' })
    )
  end

  it 'checks monitorable connections' do
    described_class.perform_now

    expect(Optimia::ChannelManager::HealthMonitorService).to have_received(:new).with(connection: connection)
  end
end
