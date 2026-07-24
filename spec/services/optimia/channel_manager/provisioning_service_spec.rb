# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::ProvisioningService do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }

  it 'does not create inbox when recreation is disabled' do
    connection = create(
      :optimia_channel_connection,
      account: account,
      lifecycle_status: 'archived',
      inbox_recreation_enabled: false
    )

    expect do
      described_class.new(connection: connection, performed_by: admin).perform!
    end.not_to change(Inbox, :count)
  end
end
