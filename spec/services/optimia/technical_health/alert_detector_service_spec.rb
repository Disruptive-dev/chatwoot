# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::AlertDetectorService do
  let(:checks) do
    [
      { component: 'evolution', status: 'critical', metadata: {} },
      { component: 'sidekiq', status: 'healthy', metadata: { 'processes' => 1 } }
    ]
  end

  it 'creates an alert when evolution is critical' do
    expect do
      described_class.new(checks).detect!
    end.to change(OptimiaTechnicalAlert.where(alert_type: 'evolution_down'), :count).by(1)
  end
end
