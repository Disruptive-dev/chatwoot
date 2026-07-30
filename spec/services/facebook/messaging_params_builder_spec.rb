# frozen_string_literal: true

require 'rails_helper'

describe Facebook::MessagingParamsBuilder do
  describe '.build' do
    let(:base_params) do
      {
        recipient: { id: '12345' },
        message: { text: 'hello' }
      }
    end

    context 'when human agent is disabled' do
      before do
        InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').delete_all
      end

      it 'uses RESPONSE messaging_type without tag' do
        result = described_class.build(base_params)

        expect(result[:messaging_type]).to eq('RESPONSE')
        expect(result).not_to have_key(:tag)
      end

      it 'does not include ACCOUNT_UPDATE' do
        result = described_class.build(base_params)

        expect(result[:tag]).to be_nil
        expect(result.values).not_to include('ACCOUNT_UPDATE')
      end
    end

    context 'when human agent is enabled' do
      before do
        InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').first_or_create(value: true)
      end

      it 'uses MESSAGE_TAG with HUMAN_AGENT' do
        result = described_class.build(base_params)

        expect(result[:messaging_type]).to eq('MESSAGE_TAG')
        expect(result[:tag]).to eq('HUMAN_AGENT')
      end
    end
  end
end
