# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::DockerChecker do
  it 'returns unknown when swarm service is not configured' do
    result = described_class.new.check

    expect(result[:status]).to eq('unknown')
    expect(result[:metadata][:hostname]).to eq('unknown')
  end
end
