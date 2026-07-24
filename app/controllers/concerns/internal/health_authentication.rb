# frozen_string_literal: true

module Internal
  module HealthAuthentication
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_internal_health!
    end

    private

    def authenticate_internal_health!
      return if warden&.authenticated?(:super_admin)

      token = request.headers['Authorization'].to_s.delete_prefix('Bearer ').presence
      expected = ENV.fetch('OPTIMIA_INTERNAL_HEALTH_TOKEN', nil).presence
      return if expected.present? && ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected)

      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
