# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::TimelineBuilderService do
  let(:account) { create(:account) }
  let(:connection) { create(:optimia_channel_connection, account: account, state: 'ready') }

  before do
    OptimiaChannelConnectionAudit.create!(
      optimia_channel_connection: connection,
      account: account,
      action: 'connected',
      to_state: 'connected'
    )
  end

  it 'builds readable timeline events from audits' do
    events = described_class.new(connection: connection).build

    expect(events.first[:summary]).to eq('Connected')
    expect(events.first[:event_type]).to eq('connected')
  end
end
