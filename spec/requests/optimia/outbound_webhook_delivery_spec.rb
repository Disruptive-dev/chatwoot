# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OptimiA outbound via API inbox webhook', type: :request do
  let(:account) { create(:account) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:webhook_url) { 'https://evo.example.com/chatwoot/webhook/optimia-1-test' }
  let(:channel) { create(:channel_api, account: account, webhook_url: webhook_url) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:listener) { WebhookListener.instance }

  it 'dispatches outgoing message_created events to the Evolution webhook URL' do
    message = create(
      :message,
      account: account,
      inbox: inbox,
      conversation: conversation,
      message_type: :outgoing,
      content: 'Prueba salida OptimiA'
    )

    expect(WebhookJob).to receive(:perform_later).with(
      webhook_url,
      message.webhook_data.merge(event: 'message_created'),
      :api_inbox_webhook
    ).once

    listener.message_created(Events::Base.new('message.created', Time.zone.now, message: message))
  end

  it 'does not change webhook delivery for unrelated inbox types' do
    stub_request(:post, 'https://waba.360dialog.io/v1/configs/webhook')
      .to_return(status: 200, body: '{}', headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, 'https://waba.360dialog.io/v1/configs/templates')
      .to_return(status: 200, body: '{"waba_templates":[]}', headers: { 'Content-Type' => 'application/json' })

    whatsapp_channel = create(:channel_whatsapp, account: account)
    whatsapp_inbox = whatsapp_channel.inbox
    whatsapp_conversation = create(:conversation, account: account, inbox: whatsapp_inbox)
    message = create(
      :message,
      account: account,
      inbox: whatsapp_inbox,
      conversation: whatsapp_conversation,
      message_type: :outgoing,
      content: 'WhatsApp nativo'
    )

    expect(WebhookJob).not_to receive(:perform_later).with(
      webhook_url,
      anything,
      :api_inbox_webhook
    )

    listener.message_created(Events::Base.new('message.created', Time.zone.now, message: message))
  end
end
