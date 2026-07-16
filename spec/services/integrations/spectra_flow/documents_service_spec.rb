# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::SpectraFlow::DocumentsService do
  let(:account) { create(:account) }

  describe '#list_sendable' do
    it 'returns configuration error payload without raising' do
      allow(Integrations::SpectraFlow::Client).to receive(:new)
        .and_raise(Integrations::SpectraFlow::Client::ConfigurationError.new(
                     'Spectra Flow bearer token not configured',
                     error_code: 'spectra_not_configured'
                   ))

      result = described_class.new(account: account).list_sendable(q: '')
      expect(result[:status]).to eq(503)
      expect(result[:error_code]).to eq('spectra_not_configured')
    end
  end

  describe '#health_check' do
    it 'delegates to client health_check' do
      client = instance_double(Integrations::SpectraFlow::Client, health_check: { ok: true })
      allow(Integrations::SpectraFlow::Client).to receive(:new).and_return(client)

      result = described_class.new(account: account).health_check
      expect(result[:ok]).to be(true)
    end
  end
end
