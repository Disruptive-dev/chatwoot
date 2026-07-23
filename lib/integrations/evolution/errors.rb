# frozen_string_literal: true

module Integrations
  module Evolution
    module Errors
      ERROR_CODES = {
        not_configured: 'evolution_not_configured',
        invalid_url: 'evolution_invalid_url',
        upstream_unavailable: 'evolution_upstream_unavailable',
        timeout: 'evolution_timeout',
        instance_not_found: 'evolution_instance_not_found',
        connection_failed: 'evolution_connection_failed',
        invalid_response: 'evolution_invalid_response'
      }.freeze

      def self.error_code_for_status(status)
        case status.to_i
        when 401, 403 then ERROR_CODES[:connection_failed]
        when 404 then ERROR_CODES[:instance_not_found]
        when 408, 504 then ERROR_CODES[:timeout]
        when 502, 503 then ERROR_CODES[:upstream_unavailable]
        else ERROR_CODES[:connection_failed]
        end
      end
    end

    class ConfigurationError < StandardError
      attr_reader :error_code, :config_sources

      def initialize(message, error_code:, config_sources: {})
        super(message)
        @error_code = error_code
        @config_sources = config_sources
      end

      def http_status
        503
      end
    end
  end
end
