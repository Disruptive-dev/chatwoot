# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::PostgresChecker do
  it 'returns healthy when database responds' do
    result = described_class.new.check

    expect(result[:status]).to eq('healthy')
    expect(result[:metadata][:db_latency_ms]).to be_a(Integer)
  end
end
