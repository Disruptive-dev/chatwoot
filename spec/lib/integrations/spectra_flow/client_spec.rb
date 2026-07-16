# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::SpectraFlow::Client do
  let(:account) do
    create(:account, custom_attributes: {
             'spectra_flow_api_url' => 'https://spectra.example.com',
             'spectra_flow_bearer_token' => 'tenant-token'
           })
  end

  describe '.credentials_for' do
    it 'prefers account custom attributes over global env' do
      creds = described_class.credentials_for(account)
      expect(creds[:api_base_url]).to eq('https://spectra.example.com')
      expect(creds[:bearer_token]).to eq('tenant-token')
    end

    it 'supports global SPECTRA_FLOW_API_TOKEN fallback' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_URL', nil).and_return('https://global.example.com')
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_TOKEN', nil).and_return('global-token')

      creds = described_class.credentials_for(create(:account))
      expect(creds[:bearer_token]).to eq('global-token')
    end
  end

  describe '.valid_api_url?' do
    it 'accepts https urls with host' do
      expect(described_class.valid_api_url?('https://spectra.example.com')).to be(true)
    end

    it 'rejects invalid urls' do
      expect(described_class.valid_api_url?('not-a-url')).to be(false)
      expect(described_class.valid_api_url?('ftp://spectra.example.com')).to be(false)
    end
  end

  describe '.sanitize_filename' do
    it 'preserves UTF-8 characters in filenames' do
      expect(described_class.sanitize_filename('Presupuesto_año_2026.pdf')).to eq('Presupuesto_año_2026.pdf')
    end

    it 'strips path traversal characters' do
      expect(described_class.sanitize_filename('../../etc/passwd')).to eq('passwd')
    end
  end

  describe '#initialize' do
    it 'raises when api url is invalid' do
      invalid_account = create(:account, custom_attributes: {
                                 'spectra_flow_api_url' => 'not-a-url',
                                 'spectra_flow_bearer_token' => 'token'
                               })

      expect { described_class.new(account: invalid_account) }
        .to raise_error(Integrations::SpectraFlow::Client::ConfigurationError, /invalid/i)
    end
  end

  describe '#list_sendable' do
    it 'returns sanitized payload without tenant_id' do
      client = described_class.new(account: account)
      response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: {
          'items' => [{
            'id' => '1',
            'title' => 'Doc',
            'tenant_id' => 'secret',
            'storage_path' => '/uploads/secret.pdf'
          }],
          'tenant_id' => 'secret'
        }
      )
      allow(described_class).to receive(:get).and_return(response)

      result = client.list_sendable(q: 'presupuesto')
      expect(result[:data]['tenant_id']).to be_nil
      expect(result[:data]['items'].first['tenant_id']).to be_nil
      expect(result[:data]['items'].first['storage_path']).to be_nil
      expect(result[:data]['items'].first['title']).to eq('Doc')
    end
  end

  describe '#create_download_token' do
    it 'rejects invalid document ids' do
      client = described_class.new(account: account)
      result = client.create_download_token('../bad-id')
      expect(result[:status]).to eq(422)
    end
  end
end
