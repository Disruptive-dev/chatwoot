# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SuperAdmin::TechnicalHealthController, type: :request do
  let(:super_admin) { create(:super_admin) }

  before do
    allow(Integrations::Evolution::Client).to receive(:configured?).and_return(false)
    allow(Sidekiq::Stats).to receive(:new).and_return(
      instance_double(Sidekiq::Stats, workers_size: 1, enqueued: 0, failed: 0, processed: 1, default_queue_latency: 0)
    )
    allow(Sidekiq::ProcessSet).to receive(:new).and_return([double('process')])
    allow(Sidekiq::DeadSet).to receive(:new).and_return(double(size: 0))
    allow(Sidekiq::RetrySet).to receive(:new).and_return(double(size: 0))
    allow(Sidekiq::Queue).to receive(:all).and_return([])
    allow(Sidekiq::Cron::Job).to receive(:all).and_return([])
  end

  describe 'GET /super_admin/technical_health' do
    it 'redirects unauthenticated users' do
      get super_admin_technical_health_path

      expect(response).to redirect_to(new_super_admin_session_path)
    end
  end

  describe 'GET /super_admin/technical_health/diagnose' do
    it 'allows authenticated super admins' do
      sign_in(super_admin, scope: :super_admin)

      get diagnose_super_admin_technical_health_path, headers: { 'Accept' => 'application/json' }

      expect(response).to have_http_status(:success)
      expect(response.parsed_body).to include('score')
    end
  end
end
