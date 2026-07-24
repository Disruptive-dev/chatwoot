# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::Checkers::SchedulerChecker do
  it 'returns degraded when no cron jobs are enabled' do
    job = instance_double(Sidekiq::Cron::Job, enabled?: false, name: 'test_job')
    allow(Sidekiq::Cron::Job).to receive(:all).and_return([job])

    result = described_class.new.check

    expect(result[:status]).to eq('degraded')
  end
end
