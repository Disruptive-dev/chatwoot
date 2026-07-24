# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::EvolutionChecker do
  it 'returns unknown when evolution is not configured' do
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(false)

    result = described_class.new.check

    expect(result[:status]).to eq('unknown')
    expect(result[:metadata][:configured]).to be(false)
  end

  it 'returns critical when evolution health check fails' do
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(true)
    allow_any_instance_of(Integrations::Evolution::Client).to receive(:health_check).and_return(ok: false)

    result = described_class.new.check

    expect(result[:status]).to eq('critical')
  end
end
