# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SuperAdmin::TechnicalHealthController, type: :request do
  describe 'GET /super_admin/technical_health' do
    it 'redirects unauthenticated users' do
      get super_admin_technical_health_path

      expect(response).to redirect_to(new_super_admin_session_path)
    end
  end
end
