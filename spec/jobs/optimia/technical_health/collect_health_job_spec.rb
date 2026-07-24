# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::CollectHealthJob do
  before do
    allow(Redis::Alfred).to receive(:set).and_return(true)
    allow(Redis::Alfred).to receive(:delete)
    allow(Optimia::TechnicalHealth::Orchestrator).to receive(:run!)
  end

  it 'runs the orchestrator when lock is acquired' do
    described_class.perform_now

    expect(Optimia::TechnicalHealth::Orchestrator).to have_received(:run!)
  end

  it 'skips orchestrator when lock is not acquired' do
    allow(Redis::Alfred).to receive(:set).and_return(false)

    described_class.perform_now

    expect(Optimia::TechnicalHealth::Orchestrator).not_to have_received(:run!)
  end

  it 'releases the lock after execution' do
    described_class.perform_now

    expect(Redis::Alfred).to have_received(:delete).with(Redis::Alfred::OPTIMIA_TECHNICAL_HEALTH_COLLECT_LOCK)
  end
end
