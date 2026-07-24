# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::CollectHealthJob do
  it 'runs the orchestrator' do
    expect(Optimia::TechnicalHealth::Orchestrator).to receive(:run!)

    described_class.perform_now
  end
end
