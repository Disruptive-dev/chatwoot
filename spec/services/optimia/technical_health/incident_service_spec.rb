# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Optimia::TechnicalHealth::IncidentService do
  let(:alert) do
    OptimiaTechnicalAlert.create!(
      alert_type: 'evolution_down',
      component: 'evolution',
      severity: 'critical',
      status: 'open',
      message: 'Evolution down',
      opened_at: Time.current
    )
  end

  it 'creates an incident from an alert' do
    expect do
      described_class.new.create_from_alert!(alert)
    end.to change(OptimiaTechnicalIncident, :count).by(1)
  end

  it 'acknowledges an incident' do
    incident = described_class.new.create_from_alert!(alert)

    described_class.new.acknowledge!(incident: incident, responsible: 'ops@example.com')

    expect(incident.reload.status).to eq('acknowledged')
  end

  it 'resolves an incident' do
    incident = described_class.new.create_from_alert!(alert)

    described_class.new.resolve!(
      incident: incident,
      root_cause: 'network',
      action_taken: 'restarted service',
      responsible: 'ops@example.com'
    )

    expect(incident.reload.status).to eq('resolved')
    expect(incident.root_cause).to eq('network')
  end
end
