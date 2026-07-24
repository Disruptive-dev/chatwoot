# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::NocDashboardService do
  it 'reflects degraded component in dashboard' do
    OptimiaTechnicalHealthCheck.create!(
      component: 'redis',
      status: 'degraded',
      latency_ms: 300,
      checked_at: Time.current,
      metadata: {}
    )

    dashboard = described_class.build
    redis = dashboard[:components].find { |item| item[:component] == 'redis' }

    expect(redis[:status]).to eq('degraded')
  end

  it 'reflects critical component in dashboard' do
    OptimiaTechnicalHealthCheck.create!(
      component: 'evolution',
      status: 'critical',
      latency_ms: 0,
      checked_at: Time.current,
      metadata: {}
    )

    dashboard = described_class.build
    evolution = dashboard[:components].find { |item| item[:component] == 'evolution' }

    expect(evolution[:status]).to eq('critical')
  end
end
