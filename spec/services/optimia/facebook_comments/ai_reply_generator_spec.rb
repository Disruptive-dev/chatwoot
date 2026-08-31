# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::FacebookComments::AiReplyGenerator do
  let(:account) { create(:account) }
  let(:property_context) do
    Optimia::FacebookComments::PropertyContext.new(
      property_id: 'prop_1',
      post_id: 'post_1',
      source: 'manual',
      confidence: 1.0,
      known_facts: { 'price' => 'USD 200.000' }
    )
  end

  before do
    account.update!(custom_attributes: { 'optimia_facebook_comment_ai_reply_enabled' => true })
  end

  it 'includes official price for price intent' do
    reply = described_class.new(
      account: account,
      intent: :price,
      property_context: property_context,
      message: 'Precio?'
    ).generate

    expect(reply).to include('USD 200.000')
    expect(reply).not_to match(/c[oó]mo te llam/i)
  end

  it 'does not invent price when unknown' do
    empty_context = Optimia::FacebookComments::PropertyContext.new(
      property_id: nil,
      post_id: 'post_1',
      source: 'unmapped',
      confidence: 0.0,
      known_facts: {}
    )

    reply = described_class.new(
      account: account,
      intent: :price,
      property_context: empty_context,
      message: 'Precio?'
    ).generate

    expect(reply).not_to match(/USD|ARS|\$\d/)
    expect(reply).to include('precio')
  end
end
