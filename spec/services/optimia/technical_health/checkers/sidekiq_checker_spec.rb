# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::SidekiqChecker do
  before do
    allow(Sidekiq::Stats).to receive(:new).and_return(
      instance_double(Sidekiq::Stats, workers_size: 0, enqueued: 0, failed: 0, processed: 0, default_queue_latency: 0)
    )
    allow(Sidekiq::ProcessSet).to receive(:new).and_return([])
  end

  it 'returns critical when no sidekiq processes are running' do
    result = described_class.new.check

    expect(result[:status]).to eq('critical')
    expect(result[:metadata][:processes]).to eq(0)
  end
end
