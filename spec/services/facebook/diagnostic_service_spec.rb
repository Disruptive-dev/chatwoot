# frozen_string_literal: true

require 'rails_helper'

describe Facebook::DiagnosticService do
  subject(:service) { described_class.new(inbox: facebook_inbox, psid: 'psid-123') }

  let(:account) { create(:account) }
  let(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let(:fb_object) { instance_double(Koala::Facebook::API) }

  before do
    allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
    allow(GlobalConfigService).to receive(:load).with('FACEBOOK_API_VERSION', 'v18.0').and_return('v18.0')
    allow(GlobalConfigService).to receive(:load).with('FB_APP_ID', '').and_return('app-id')
    allow(GlobalConfigService).to receive(:load).with('FB_APP_SECRET', '').and_return('app-secret')
    allow(fb_object).to receive(:get_object).with(facebook_channel.page_id, fields: 'id,name').and_return(
      { 'id' => facebook_channel.page_id, 'name' => 'Test Page' }
    )
    allow(fb_object).to receive(:get_object).with('psid-123', fields: Facebook::ProfileFetcher::PROFILE_FIELDS).and_return(
      { 'name' => 'Jane Doe' }
    )
    allow(fb_object).to receive(:get_object).with('debug_token', input_token: facebook_channel.page_access_token).and_return(
      { 'data' => { 'is_valid' => true, 'type' => 'PAGE', 'scopes' => %w[pages_messaging], 'expires_at' => 0 } }
    )
  end

  it 'returns masked diagnostics without printing the token' do
    result = service.perform

    aggregate_failures do
      expect(result[:inbox_id]).to eq(facebook_inbox.id)
      expect(result[:page_access_token_present]).to be(true)
      expect(result[:page_access_token_fingerprint]).to be_present
      expect(result[:page_access_token_fingerprint].length).to eq(12)
      expect(result.to_json).not_to include(facebook_channel.page_access_token)
      expect(result[:page_lookup]).to eq('succeeded')
      expect(result[:profile_lookup]).to eq('succeeded')
      expect(result[:token_debug]).to eq('succeeded')
    end
  end

  it 'raises for non-facebook inboxes' do
    inbox = create(:inbox, account: account)

    expect do
      described_class.new(inbox: inbox).perform
    end.to raise_error(ArgumentError, 'Inbox channel is not Channel::FacebookPage')
  end
end
