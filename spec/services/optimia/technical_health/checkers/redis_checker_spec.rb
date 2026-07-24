# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::RedisChecker do
  it 'returns critical when redis is unavailable' do
    allow(Redis).to receive(:new).and_raise(Redis::CannotConnectError)

    result = described_class.new.check

    expect(result[:status]).to eq('critical')
    expect(result[:metadata][:redis_latency_ms]).to be_nil
  end
end
