# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OptimiaChannelConnectionAudit do
  it 'accepts operational audit actions introduced for monitoring' do
    connection = create(:optimia_channel_connection)
    account = connection.account

    described_class::ACTIONS.each do |action|
      audit = described_class.new(
        optimia_channel_connection: connection,
        account: account,
        action: action
      )
      expect(audit).to be_valid, "expected #{action} to be valid"
    end
  end
end
