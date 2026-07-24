# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Orchestrator do
  before do
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(false)
    allow(Sidekiq::Stats).to receive(:new).and_return(
      instance_double(Sidekiq::Stats, workers_size: 1, enqueued: 0, failed: 0, processed: 1, default_queue_latency: 0, scheduled_size: 0, retry_size: 0)
    )
    allow(Sidekiq::ProcessSet).to receive(:new).and_return([double('process')])
    allow(Sidekiq::DeadSet).to receive(:new).and_return(double(size: 0))
    allow(Sidekiq::RetrySet).to receive(:new).and_return(double(size: 0))
    allow(Sidekiq::Queue).to receive(:all).and_return([])
    allow(Sidekiq::Cron::Job).to receive(:all).and_return([])
  end

  it 'does not persist when persist is false' do
    expect do
      described_class.run!(components: %w[rails], persist: false)
    end.not_to change(OptimiaTechnicalHealthCheck, :count)
  end
end
