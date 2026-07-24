# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::HealthController, type: :request do
  describe 'GET /internal/health' do
    it 'requires authentication' do
      get '/internal/health'

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns sanitized payload with token' do
      with_modified_env OPTIMIA_INTERNAL_HEALTH_TOKEN: 'test-token' do
        get '/internal/health', headers: { 'Authorization' => 'Bearer test-token' }

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to include('components')
      end
    end
  end
end
