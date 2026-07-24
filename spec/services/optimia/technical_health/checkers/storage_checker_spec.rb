# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::StorageChecker do
  it 'returns unknown when disk metrics are unavailable' do
    result = described_class.new.check

    expect(result[:status]).to eq('unknown')
    expect(result[:metadata][:disk_used_percent]).to be_nil
  end
end
