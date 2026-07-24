# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::HealthSnapshotPersister do
  it 'prunes records older than retention window' do
    old_check = OptimiaTechnicalHealthCheck.create!(
      component: 'rails',
      status: 'healthy',
      latency_ms: 1,
      checked_at: 40.days.ago,
      metadata: {}
    )
    results = [{
      component: 'rails',
      status: 'healthy',
      latency_ms: 1,
      version: nil,
      uptime_seconds: nil,
      error_count: 0,
      metadata: {},
      checked_at: Time.current
    }]

    described_class.new(results).persist!

    expect(OptimiaTechnicalHealthCheck.exists?(old_check.id)).to be(false)
    expect(OptimiaTechnicalHealthCheck.count).to eq(1)
  end
end
