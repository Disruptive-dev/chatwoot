# frozen_string_literal: true

require 'rails_helper'

# rubocop:disable RSpec/DescribeClass
describe 'Facebook Messenger hotfix isolation' do
  it 'does not change WhatsApp send service payload builder' do
    whatsapp_file = Rails.root.join('app/services/whatsapp/send_on_whatsapp_service.rb').read
    expect(whatsapp_file).not_to include('ACCOUNT_UPDATE')
    expect(whatsapp_file).not_to include('Facebook::MessagingParamsBuilder')
  end

  it 'does not change Evolution client sensitive key handling' do
    evolution_file = Rails.root.join('lib/integrations/evolution/client.rb').read
    expect(evolution_file).to include('SENSITIVE_RESPONSE_KEYS')
  end

  it 'does not change email send service' do
    email_file = Rails.root.join('app/services/email/send_on_email_service.rb').read
    expect(email_file).not_to include('Facebook::MessagingParamsBuilder')
  end

  it 'does not change webhook jobs routing' do
    send_reply_file = Rails.root.join('app/jobs/send_reply_job.rb').read
    expect(send_reply_file).to include("'Channel::Whatsapp' => ::Whatsapp::SendOnWhatsappService")
    expect(send_reply_file).to include("channel_name == 'Channel::FacebookPage'")
  end
end
# rubocop:enable RSpec/DescribeClass
