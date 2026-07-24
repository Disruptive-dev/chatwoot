# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::HealthController, type: :request do
  describe 'GET /internal/health' do
    it 'requires authentication' do
      get '/internal/health'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'rejects blank token' do
      with_modified_env OPTIMIA_INTERNAL_HEALTH_TOKEN: 'test-token' do
        get '/internal/health', headers: { 'Authorization' => 'Bearer ' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'rejects incorrect token' do
      with_modified_env OPTIMIA_INTERNAL_HEALTH_TOKEN: 'test-token' do
        get '/internal/health', headers: { 'Authorization' => 'Bearer wrong-token' }

        expect(response).to have_http_status(:unauthorized)
      end
    end

    it 'returns sanitized payload with token' do
      with_modified_env OPTIMIA_INTERNAL_HEALTH_TOKEN: 'test-token' do
        get '/internal/health', headers: { 'Authorization' => 'Bearer test-token' }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('components')
        expect(response.body).not_to include('test-token')
      end
    end

    it 'does not expose phone numbers in redis payload' do
      OptimiaTechnicalHealthCheck.create!(
        component: 'redis',
        status: 'healthy',
        latency_ms: 1,
        checked_at: Time.current,
        metadata: { phone_number: '+12345', redis_latency_ms: 1 }
      )

      with_modified_env OPTIMIA_INTERNAL_HEALTH_TOKEN: 'test-token' do
        get '/internal/health/redis', headers: { 'Authorization' => 'Bearer test-token' }

        expect(response).to have_http_status(:ok)
        expect(response.body).not_to include('+12345')
        expect(response.parsed_body['metadata']).not_to have_key('phone_number')
      end
    end
  end
end
