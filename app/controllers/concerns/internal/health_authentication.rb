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

      expected = ENV.fetch('OPTIMIA_INTERNAL_HEALTH_TOKEN', nil).presence
      return render_unauthorized if expected.blank?

      token = extract_bearer_token
      return render_unauthorized if token.blank?

      return if secure_token_match?(token, expected)

      render_unauthorized
    end

    def extract_bearer_token
      request.headers['Authorization'].to_s.delete_prefix('Bearer ').strip.presence
    end

    def secure_token_match?(token, expected)
      ActiveSupport::SecurityUtils.secure_compare(
        ::Digest::SHA256.hexdigest(token),
        ::Digest::SHA256.hexdigest(expected)
      )
    end

    def render_unauthorized
      render json: { error: 'Unauthorized' }, status: :unauthorized
    end
  end
end
