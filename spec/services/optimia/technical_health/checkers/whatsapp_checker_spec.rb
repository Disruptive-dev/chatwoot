# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::WhatsappChecker do
  let(:account) { create(:account) }

  it 'does not count archived connections as active monitor targets' do
    create(:optimia_channel_connection, account: account, state: 'ready', lifecycle_status: 'active')
    create(:optimia_channel_connection, account: account, state: 'failed', lifecycle_status: 'archived')

    result = described_class.new.check

    expect(result[:metadata][:total_connections]).to eq(1)
    expect(result[:metadata][:archived]).to eq(1)
  end

  it 'does not count deleted connections' do
    create(:optimia_channel_connection, account: account, state: 'ready', lifecycle_status: 'active')
    create(:optimia_channel_connection, account: account, state: 'failed', lifecycle_status: 'deleted')

    result = described_class.new.check

    expect(result[:metadata][:total_connections]).to eq(1)
  end
end
