# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::EventNormalizerService do
  it 'sanitizes metadata when recording events' do
    event = described_class.record!(
      component: 'redis',
      event_type: 'redis_unavailable',
      metadata: { token: 'secret', detail: 'timeout' }
    )

    expect(event.metadata).not_to have_key('token')
    expect(event.metadata['detail']).to eq('timeout')
  end
end
