# frozen_string_literal: true

require 'rails_helper'

describe Facebook::ProfileFetcher do
  subject(:fetcher) do
    described_class.new(
      channel: facebook_channel,
      psid: 'psid-123',
      account_id: account.id,
      inbox_id: facebook_inbox.id,
      outgoing_echo: outgoing_echo
    )
  end

  let(:account) { create(:account) }
  let(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let(:outgoing_echo) { false }
  let(:fb_object) { instance_double(Koala::Facebook::API) }

  before do
    allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
    allow(Rails.logger).to receive(:info)
  end

  describe '#perform' do
    it 'returns resolved profile attributes' do
      allow(fb_object).to receive(:get_object).with('psid-123', fields: described_class::PROFILE_FIELDS).and_return(
        { 'first_name' => 'Jane', 'last_name' => 'Doe' }
      )

      expect(fetcher.perform).to eq(
        name: 'Jane Doe',
        account_id: account.id,
        avatar_url: nil
      )
    end

    it 'logs profile lookup lifecycle events' do
      allow(fb_object).to receive(:get_object).and_return({ 'name' => 'Jane Doe' })

      fetcher.perform

      expect(Rails.logger).to have_received(:info).with(include('"event":"facebook_profile_lookup_started"'))
      expect(Rails.logger).to have_received(:info).with(include('"event":"facebook_profile_lookup_succeeded"'))
    end

    it 'falls back without blocking when Graph returns error code 100' do
      allow(fb_object).to receive(:get_object).and_raise(
        Koala::Facebook::ClientError.new(
          400,
          '',
          {
            'type' => 'OAuthException',
            'message' => 'Unsupported get request.',
            'error_subcode' => 33,
            'code' => 100,
            'fbtrace_id' => 'trace-abc'
          }
        )
      )
      allow(ChatwootExceptionTracker).to receive(:new).and_return(instance_double(ChatwootExceptionTracker, capture_exception: true))

      result = fetcher.perform

      expect(result[:name]).to eq(described_class::FALLBACK_NAME)
      expect(Rails.logger).to have_received(:info).with(include('"event":"facebook_profile_lookup_failed"'))
      expect(Rails.logger).to have_received(:info).with(include('"error_code":100'))
      expect(Rails.logger).to have_received(:info).with(include('"error_subcode":33'))
    end

    it 'does not report known non-blocking profile errors' do
      allow(fb_object).to receive(:get_object).and_raise(
        Koala::Facebook::ClientError.new(
          400,
          '',
          {
            'type' => 'OAuthException',
            'message' => '(#100) No profile available for this user.',
            'error_subcode' => 2_018_218,
            'code' => 100
          }
        )
      )

      expect(ChatwootExceptionTracker).not_to receive(:new)

      expect(fetcher.perform[:name]).to eq(described_class::FALLBACK_NAME)
    end

    it 'never logs access tokens' do
      allow(fb_object).to receive(:get_object).and_return({ 'name' => 'Jane Doe' })

      fetcher.perform

      expect(Rails.logger).not_to have_received(:info).with(include(facebook_channel.page_access_token))
    end

    context 'when authentication fails' do
      it 'marks channel for reauthorization and re-raises' do
        allow(fb_object).to receive(:get_object).and_raise(Koala::Facebook::AuthenticationError.new(401, 'Error validating access token'))

        expect { fetcher.perform }.to raise_error(Koala::Facebook::AuthenticationError)
        expect(facebook_channel.reload.authorization_error_count).to eq(1)
      end
    end
  end
end
