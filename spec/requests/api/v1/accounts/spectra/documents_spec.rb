# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Spectra Documents API', type: :request do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:service) { instance_double(Integrations::SpectraFlow::DocumentsService) }

  before do
    allow(Integrations::SpectraFlow::DocumentsService).to receive(:new)
      .with(account: account)
      .and_return(service)
  end

  describe 'GET /api/v1/accounts/:account_id/spectra/documents' do
    it 'returns sendable documents for account agents' do
      allow(service).to receive(:list_sendable).and_return(
        data: { 'items' => [{ 'id' => '1', 'title' => 'Contrato' }], 'count' => 1 },
        status: 200
      )

      get "/api/v1/accounts/#{account.id}/spectra/documents",
          params: { q: 'contrato' },
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Contrato')
    end

    it 'maps Spectra connection errors to public message' do
      allow(service).to receive(:list_sendable).and_return(
        error: 'timeout',
        status: 502
      )

      get "/api/v1/accounts/#{account.id}/spectra/documents",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:bad_gateway)
      expect(response.body).to include('No se pudo conectar con Spectra')
    end

    it 'maps forbidden errors to public message' do
      allow(service).to receive(:list_sendable).and_return(
        error: 'forbidden',
        status: 403
      )

      get "/api/v1/accounts/#{account.id}/spectra/documents",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include('No tenés permisos para consultar documentos')
    end

    it 'does not allow cross-account access' do
      other_account = create(:account)

      get "/api/v1/accounts/#{other_account.id}/spectra/documents",
          headers: agent.create_new_auth_token,
          as: :json

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'POST /api/v1/accounts/:account_id/spectra/documents/:id/download_token' do
    it 'returns a temporary download token' do
      allow(service).to receive(:create_download_token).and_return(
        data: { 'token' => 'temp-token', 'item_id' => 'doc-1' },
        status: 200
      )

      post "/api/v1/accounts/#{account.id}/spectra/documents/doc-1/download_token",
           headers: agent.create_new_auth_token,
           as: :json

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('temp-token')
      expect(response.body).not_to include('tenant')
    end
  end

  describe 'GET /api/v1/accounts/:account_id/spectra/documents/:id/download' do
    it 'returns not found for missing documents' do
      allow(service).to receive(:download).and_return(
        error: 'missing',
        status: 404
      )

      get "/api/v1/accounts/#{account.id}/spectra/documents/doc-1/download",
          params: { token: 'expired-token' },
          headers: agent.create_new_auth_token

      expect(response).to have_http_status(:not_found)
      expect(response.body).to include('ya no está disponible')
    end

    it 'maps expired token errors to public message' do
      allow(service).to receive(:download).and_return(
        error: 'Token de descarga inválido o expirado',
        status: 403
      )

      get "/api/v1/accounts/#{account.id}/spectra/documents/doc-1/download",
          params: { token: 'expired-token' },
          headers: agent.create_new_auth_token

      expect(response).to have_http_status(:forbidden)
      expect(response.body).to include('acceso temporal al documento expiró')
    end
  end
end
