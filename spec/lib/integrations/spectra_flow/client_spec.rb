# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Integrations::SpectraFlow::Client do
  let(:account) do
    create(:account, custom_attributes: {
             'spectra_flow_api_url' => 'https://spectra.example.com',
             'spectra_flow_bearer_token' => 'tenant-token'
           })
  end

  before do
    allow(GlobalConfig).to receive(:get).and_return({})
  end

  describe '.resolve_credentials' do
    it 'prefers account custom attributes over env' do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_URL', nil).and_return('https://env.example.com')
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).and_return('env-inbox')
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_TOKEN', nil).and_return('env-api')

      resolution = described_class.resolve_credentials(account)
      expect(resolution[:api_base_url]).to eq('https://spectra.example.com')
      expect(resolution[:bearer_token]).to eq('tenant-token')
      expect(resolution[:sources][:api_url_source]).to eq('account_custom_attributes')
      expect(resolution[:sources][:token_source]).to eq('account_custom_attributes')
    end

    it 'falls back to env when account custom attributes are blank' do
      blank_account = create(:account, custom_attributes: {
                                 'spectra_flow_api_url' => '  ',
                                 'spectra_flow_bearer_token' => ''
                               })
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_URL', nil).and_return('https://flow-api.spectra-metrics.com/api/')
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_TOKEN', nil).and_return('jwt-token-value')

      resolution = described_class.resolve_credentials(blank_account)
      expect(resolution[:api_base_url]).to eq('https://flow-api.spectra-metrics.com')
      expect(resolution[:bearer_token]).to eq('jwt-token-value')
      expect(resolution[:sources][:api_url_source]).to eq('env_api_url')
      expect(resolution[:sources][:token_source]).to eq('env_api_token')
    end

    it 'strips Bearer prefix and whitespace from token' do
      account_with_prefix = create(:account, custom_attributes: {
                                     'spectra_flow_api_url' => 'https://spectra.example.com',
                                     'spectra_flow_bearer_token' => '  Bearer jwt-abc  '
                                   })
      resolution = described_class.resolve_credentials(account_with_prefix)
      expect(resolution[:bearer_token]).to eq('jwt-abc')
    end
  end

  describe '.normalize_api_base_url' do
    it 'removes trailing slash and duplicate /api suffix' do
      expect(described_class.normalize_api_base_url('https://flow-api.spectra-metrics.com/api/')).to eq('https://flow-api.spectra-metrics.com')
    end
  end

  describe '#initialize' do
    it 'raises configuration error when api url is missing' do
      missing = create(:account)
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_URL', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).and_return(nil)
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_TOKEN', nil).and_return(nil)

      expect { described_class.new(account: missing) }
        .to raise_error(Integrations::SpectraFlow::Client::ConfigurationError) { |error|
          expect(error.error_code).to eq('spectra_not_configured')
        }
    end
  end

  describe '#list_sendable' do
    it 'calls the expected sendable url' do
      client = described_class.new(account: account)
      response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: { 'items' => [], 'count' => 0 }
      )

      expect(described_class).to receive(:get).with(
        'https://spectra.example.com/api/optimia/documents/sendable',
        hash_including(headers: hash_including('Authorization' => 'Bearer tenant-token'))
      ).and_return(response)

      result = client.list_sendable(limit: 1)
      expect(result[:status]).to eq(200)
      expect(result[:data]['items']).to eq([])
    end

    it 'maps upstream 401 to authentication error code' do
      client = described_class.new(account: account)
      response = instance_double(
        HTTParty::Response,
        success?: false,
        code: 401,
        parsed_response: { 'detail' => 'Unauthorized' },
        message: 'Unauthorized'
      )
      allow(described_class).to receive(:get).and_return(response)

      result = client.list_sendable
      expect(result[:status]).to eq(401)
      expect(result[:error_code]).to eq('spectra_authentication_failed')
    end

    it 'maps timeout to spectra_timeout' do
      client = described_class.new(account: account)
      allow(described_class).to receive(:get).and_raise(Net::ReadTimeout)

      result = client.list_sendable
      expect(result[:status]).to eq(504)
      expect(result[:error_code]).to eq('spectra_timeout')
    end

    it 'preserves download token in create_download_token response' do
      client = described_class.new(account: account)
      response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: {
          'token' => 'temp-download-token',
          'item_id' => 'doc-1',
          'expires_at' => '2026-07-16T12:00:00Z',
          'tenant_id' => 'secret-tenant'
        }
      )

      expect(described_class).to receive(:post).with(
        'https://spectra.example.com/api/optimia/documents/doc-1/download-token',
        hash_including(headers: hash_including('Authorization' => 'Bearer tenant-token'))
      ).and_return(response)

      result = client.create_download_token('doc-1')
      expect(result[:status]).to eq(200)
      expect(result[:data]['token']).to eq('temp-download-token')
      expect(result[:data]['item_id']).to eq('doc-1')
      expect(result[:data]).not_to have_key('tenant_id')
    end

    it 'falls back to SPECTRA_FLOW_INBOX_BEARER_TOKEN env' do
      blank_account = create(:account, custom_attributes: {})
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_URL', nil).and_return('https://flow.example.com')
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).and_return('spx_live_inbox_token')
      allow(ENV).to receive(:fetch).with('SPECTRA_FLOW_API_TOKEN', nil).and_return(nil)

      resolution = described_class.resolve_credentials(blank_account)
      expect(resolution[:bearer_token]).to eq('spx_live_inbox_token')
      expect(resolution[:sources][:token_source]).to eq('env_inbox_token')
    end

    it 'does not include token in logs' do
      client = described_class.new(account: account)
      response = instance_double(
        HTTParty::Response,
        success?: true,
        code: 200,
        parsed_response: { 'items' => [] }
      )
      allow(described_class).to receive(:get).and_return(response)

      expect(Rails.logger).to receive(:info) do |payload|
        json = payload.is_a?(String) ? payload : payload.to_json
        expect(json).not_to include('tenant-token')
        expect(json).not_to include('Authorization')
      end

      client.list_sendable
    end
  end

  describe '#health_check' do
    it 'returns ok summary without secrets' do
      client = described_class.new(account: account)
      allow(client).to receive(:list_sendable).and_return(data: { 'items' => [] }, status: 200)

      result = client.health_check
      expect(result[:ok]).to be(true)
      expect(result[:host]).to eq('spectra.example.com')
      expect(result[:path]).to eq('/api/optimia/documents/sendable')
      expect(result.to_json).not_to include('tenant-token')
    end
  end
end
