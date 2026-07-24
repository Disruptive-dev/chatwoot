# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::Optimia::TechnicalHealth::Sanitizer do
  it 'removes sensitive keys from hashes' do
    payload = { token: 'secret', webhook_url: 'https://x', status: 'ok' }
    result = described_class.sanitize(payload)

    expect(result).to eq({ status: 'ok' })
  end

  it 'removes phone_number and nested secrets' do
    payload = { phone_number: '+1234', nested: { api_key: 'x', detail: 'ok' } }
    result = described_class.sanitize(payload)

    expect(result).to eq({ nested: { detail: 'ok' } })
  end
end
