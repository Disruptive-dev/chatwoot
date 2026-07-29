# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'optimia:facebook:diagnose' do
  let(:account) { create(:account) }
  let(:facebook_channel) { create(:channel_facebook_page, account: account) }
  let(:facebook_inbox) { create(:inbox, channel: facebook_channel, account: account) }
  let(:fb_object) { instance_double(Koala::Facebook::API) }

  before do
    Rails.application.load_tasks
    allow(Koala::Facebook::API).to receive(:new).and_return(fb_object)
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('FACEBOOK_API_VERSION', 'v18.0').and_return('v18.0')
    allow(GlobalConfigService).to receive(:load).with('FB_APP_ID', '').and_return('')
    allow(GlobalConfigService).to receive(:load).with('FB_APP_SECRET', '').and_return('')
    allow(fb_object).to receive(:get_object).with(facebook_channel.page_id, fields: 'id,name').and_return(
      { 'id' => facebook_channel.page_id, 'name' => 'Test Page' }
    )
  end

  it 'runs read-only diagnostics for an inbox' do
    expect do
      Rake::Task['optimia:facebook:diagnose'].invoke(facebook_inbox.id)
    end.to output(include('"page_lookup":"succeeded"')).to_stdout

    Rake::Task['optimia:facebook:diagnose'].reenable
  end
end
# rubocop:enable RSpec/DescribeClass
