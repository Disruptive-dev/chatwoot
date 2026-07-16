# frozen_string_literal: true

module Integrations
  module SpectraFlow
    module Errors
      ERROR_CODES = {
        not_configured: 'spectra_not_configured',
        invalid_url: 'spectra_not_configured',
        authentication_failed: 'spectra_authentication_failed',
        forbidden: 'spectra_forbidden',
        endpoint_not_found: 'spectra_endpoint_not_found',
        timeout: 'spectra_timeout',
        upstream_unavailable: 'spectra_upstream_unavailable',
        invalid_response: 'spectra_invalid_response'
      }.freeze

      def self.error_code_for_status(status)
        case status.to_i
        when 401 then ERROR_CODES[:authentication_failed]
        when 403 then ERROR_CODES[:forbidden]
        when 404 then ERROR_CODES[:endpoint_not_found]
        when 408, 504 then ERROR_CODES[:timeout]
        when 500, 502, 503 then ERROR_CODES[:upstream_unavailable]
        else ERROR_CODES[:upstream_unavailable]
        end
      end
    end

    class Client
      class ConfigurationError < StandardError
        attr_reader :error_code, :http_status, :config_sources

        def initialize(message, error_code: Errors::ERROR_CODES[:not_configured], http_status: 503, config_sources: {})
          @error_code = error_code
          @http_status = http_status
          @config_sources = config_sources
          super(message)
        end
      end
    end
  end
end
