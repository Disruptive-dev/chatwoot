# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::ConnectionAlertService do
  let(:account) { create(:account) }
  let(:connection) { create(:optimia_channel_connection, account: account, state: 'ready') }
  let(:service) { described_class.new(connection: connection) }

  before do
    Redis::Alfred.delete(described_class.cooldown_key(connection.id, 'disconnected'))
  end

  it 'creates an internal alert record' do
    alert = service.notify!(alert_type: 'disconnected', message: 'Disconnected')

    expect(alert).to be_persisted
    expect(connection.optimia_channel_connection_alerts.count).to eq(1)
  end

  it 'respects cooldown and avoids duplicate alerts' do
    service.notify!(alert_type: 'disconnected', message: 'Disconnected')
    second = service.notify!(alert_type: 'disconnected', message: 'Disconnected again')

    expect(second).to be_nil
    expect(connection.optimia_channel_connection_alerts.count).to eq(1)
  end
end
