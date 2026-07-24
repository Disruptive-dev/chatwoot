# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::BaseChecker do
  before do
    stub_const('TestHealthyChecker', Class.new(described_class) do
      def perform_check
        { status: 'healthy', metadata: {} }
      end
    end)

    stub_const('TestFailingChecker', Class.new(described_class) do
      def perform_check
        raise StandardError, 'token=abc123 failed'
      end
    end)

    stub_const('TestSlowChecker', Class.new(described_class) do
      def perform_check
        sleep 0.05
        { status: 'healthy', metadata: {} }
      end
    end)
  end

  it 'sanitizes error messages in metadata' do
    result = TestFailingChecker.new.check

    expect(result[:status]).to eq('critical')
    expect(result[:metadata][:message]).to eq('token=abc123 failed')
  end

  it 'returns degraded on timeout' do
    stub_const('Optimia::TechnicalHealth::Checkers::BaseChecker::CHECK_TIMEOUT_SECONDS', 0.01)

    result = TestSlowChecker.new.check

    expect(result[:status]).to eq('degraded')
    expect(result[:metadata][:error_class]).to eq('Timeout::Error')
  end
end
