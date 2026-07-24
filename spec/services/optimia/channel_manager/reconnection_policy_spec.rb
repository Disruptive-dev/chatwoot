# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::ReconnectionPolicy do
  let(:account) { create(:account) }
  let(:connection) do
    create(
      :optimia_channel_connection,
      account: account,
      state: 'ready',
      external_instance_id: 'optimia-1-test',
      reconnect_attempts_count: 0
    )
  end
  let(:alert_service) { instance_double(Optimia::ChannelManager::ConnectionAlertService) }
  let(:policy) { described_class.new(connection: connection, alert_service: alert_service) }

  before do
    allow(alert_service).to receive(:notify!)
  end

  it 'keeps ready when Evolution reports open' do
    status = Integrations::Optimia::ChannelManager::ProviderAdapter::StatusResult.new(
      remote_state: 'open',
      phone_number: '+5491111111111',
      metadata: {}
    )

    policy.apply_from_status!(status)

    expect(connection.reload.state).to eq('ready')
    expect(connection.reconnect_attempts_count).to eq(0)
  end

  it 'moves to reconnecting on temporary close without logout' do
    status = Integrations::Optimia::ChannelManager::ProviderAdapter::StatusResult.new(
      remote_state: 'connecting',
      phone_number: nil,
      metadata: {}
    )

    policy.apply_from_status!(status)

    expect(connection.reload.state).to eq('reconnecting')
    expect(alert_service).to have_received(:notify!).with(hash_including(alert_type: 'reconnect_started'))
  end

  it 'requires qr after max reconnect attempts' do
    connection.update!(reconnect_attempts_count: Integrations::Optimia::ChannelManager::MonitorConfig.reconnect_max_attempts - 1)
    status = Integrations::Optimia::ChannelManager::ProviderAdapter::StatusResult.new(
      remote_state: 'connecting',
      phone_number: nil,
      metadata: {}
    )

    policy.apply_from_status!(status)

    expect(connection.reload.state).to eq('qr_required')
    expect(alert_service).to have_received(:notify!).with(hash_including(alert_type: 'qr_required'))
  end

  it 'marks degraded on upstream failure' do
    policy.apply_upstream_failure!(error_code: 'evolution_upstream_unavailable')

    expect(connection.reload.state).to eq('degraded')
    expect(alert_service).to have_received(:notify!).with(hash_including(alert_type: 'evolution_unavailable'))
  end
end
