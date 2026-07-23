# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OptimiaChannelConnection do
  describe 'state machine' do
    let(:connection) { create(:optimia_channel_connection, state: 'draft') }

    it 'transitions from draft to creating' do
      expect { connection.transition_to!('creating') }
        .to change(connection, :state).from('draft').to('creating')
    end

    it 'rejects invalid transitions' do
      expect { connection.transition_to!('ready') }
        .to raise_error(ArgumentError, /Invalid transition/)
    end
  end

  describe '#public_attributes' do
    it 'does not expose encrypted credentials' do
      connection = create(:optimia_channel_connection, encrypted_credentials: { token: 'secret' }.to_json)
      expect(connection.public_attributes).not_to have_key(:encrypted_credentials)
      expect(connection.public_attributes).not_to have_key(:connection_metadata)
    end
  end
end
