# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::ChannelManager::OutboundStatusProcessor do
  let(:account) { create(:account) }
  let(:channel) { create(:channel_api, account: account) }
  let(:inbox) { channel.inbox }
  let(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:connection) do
    create(:optimia_channel_connection, account: account, inbox: inbox, provider: 'evolution', external_instance_id: 'optimia-1-test')
  end
  let(:message) do
    create(:message, account: account, inbox: inbox, conversation: conversation, message_type: :outgoing, status: :sent)
  end

  def process(status:, external_error: nil, source_id: nil)
    described_class.new(
      message: message,
      status: status,
      external_error: external_error,
      source_id: source_id
    ).perform!
  end

  it 'marks delivered from sent' do
    expect(process(status: 'delivered')).to be(true)
    expect(message.reload.status).to eq('delivered')
  end

  it 'marks read from delivered' do
    message.update!(status: :delivered)
    expect(process(status: 'read')).to be(true)
    expect(message.reload.status).to eq('read')
  end

  it 'ignores duplicate delivered webhook' do
    message.update!(status: :delivered)
    expect(process(status: 'delivered')).to be(true)
    expect(message.reload.status).to eq('delivered')
  end

  it 'ignores stale delivered after read' do
    message.update!(status: :read)
    expect(process(status: 'delivered')).to be(false)
    expect(message.reload.status).to eq('read')
  end

  it 'marks failed from sent on real error' do
    expect(process(status: 'failed', external_error: 'upstream rejected')).to be(true)
    expect(message.reload.status).to eq('failed')
    expect(message.external_error).to eq('upstream rejected')
  end

  it 'ignores failed webhook after delivered' do
    message.update!(status: :delivered)
    expect(process(status: 'failed', external_error: 'late failure')).to be(false)
    expect(message.reload.status).to eq('delivered')
  end

  it 'persists source_id when blank' do
    process(status: 'sent', source_id: 'REMOTE-123')
    expect(message.reload.source_id).to eq('REMOTE-123')
  end

  it 'does not overwrite existing source_id' do
    message.update!(source_id: 'EXISTING-1')
    process(status: 'sent', source_id: 'REMOTE-123')
    expect(message.reload.source_id).to eq('EXISTING-1')
  end
end
