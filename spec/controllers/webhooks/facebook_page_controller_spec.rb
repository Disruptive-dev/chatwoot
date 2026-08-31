# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Webhooks::FacebookPageController, type: :request do
  let(:verify_token) { 'test_verify_token' }
  let(:app_secret) { 'test_app_secret' }

  before do
    allow(GlobalConfigService).to receive(:load).and_call_original
    allow(GlobalConfigService).to receive(:load).with('FB_VERIFY_TOKEN', '').and_return(verify_token)
    allow(GlobalConfigService).to receive(:load).with('FB_APP_SECRET', '').and_return(app_secret)
  end

  describe 'GET /webhooks/facebook' do
    it 'verifies subscription challenge' do
      get '/webhooks/facebook', params: {
        'hub.mode' => 'subscribe',
        'hub.verify_token' => verify_token,
        'hub.challenge' => 'challenge_123'
      }

      expect(response).to have_http_status(:ok)
      expect(response.body).to eq('challenge_123')
    end
  end

  describe 'POST /webhooks/facebook' do
    let(:payload) do
      {
        object: 'page',
        entry: [{ id: 'page_1', changes: [] }]
      }
    end

  let(:body) { payload.to_json }
  let(:signature) { "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, body)}" }

    it 'enqueues job with valid signature' do
      expect do
        post '/webhooks/facebook',
             params: body,
             headers: {
               'CONTENT_TYPE' => 'application/json',
               'X-Hub-Signature-256' => signature
             }
      end.to have_enqueued_job(Webhooks::FacebookPageEventsJob)

      expect(response).to have_http_status(:ok)
    end

    it 'rejects invalid signature' do
      post '/webhooks/facebook',
           params: body,
           headers: {
             'CONTENT_TYPE' => 'application/json',
             'X-Hub-Signature-256' => 'sha256=invalid'
           }

      expect(response).to have_http_status(:unauthorized)
    end
  end
end
