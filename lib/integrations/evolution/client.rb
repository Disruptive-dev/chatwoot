# frozen_string_literal: true

require_relative 'errors'

module Integrations
  module Evolution
    class Client
      include HTTParty

      DEFAULT_TIMEOUT = 20
      QR_TTL_SECONDS = 60
      SENSITIVE_RESPONSE_KEYS = %w[
        hash token apikey api_key instanceId instanceToken
        chatwootToken chatwootUrl chatwootAccountId
      ].freeze

      def initialize
        resolution = self.class.resolve_credentials
        @api_base_url = resolution[:api_base_url]
        @api_key = resolution[:api_key]
        @config_sources = resolution[:sources]
        validate_configuration!(resolution)
      end

      def create_instance(instance_name:, qrcode: true, number: nil)
        body = {
          instanceName: instance_name,
          qrcode: qrcode,
          integration: 'WHATSAPP-BAILEYS'
        }
        body[:number] = number if number.present?

        request_json(:post, '/instance/create', body: body)
      end

      def fetch_instances(instance_name: nil)
        query = {}
        query[:instanceName] = instance_name if instance_name.present?
        request_json(:get, '/instance/fetchInstances', query: query)
      end

      def connect_instance(instance_name, number: nil)
        query = {}
        query[:number] = number if number.present?
        request_json(:get, "/instance/connect/#{encoded_instance_name(instance_name)}", query: query)
      end

      def connection_state(instance_name)
        request_json(:get, "/instance/connectionState/#{encoded_instance_name(instance_name)}")
      end

      def logout_instance(instance_name)
        request_json(:delete, "/instance/logout/#{encoded_instance_name(instance_name)}")
      end

      def set_chatwoot(instance_name, chatwoot_config:)
        request_json(:post, "/chatwoot/set/#{encoded_instance_name(instance_name)}", body: chatwoot_config)
      end

      def health_check
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = fetch_instances
        duration_ms = elapsed_ms(started)

        if result[:error].present?
          {
            ok: false,
            status: result[:status],
            error_code: result[:error_code],
            duration_ms: duration_ms,
            host: safe_host(@api_base_url),
            config_sources: self.class.safe_config_sources(@config_sources)
          }
        else
          {
            ok: true,
            status: 200,
            duration_ms: duration_ms,
            host: safe_host(@api_base_url),
            config_sources: self.class.safe_config_sources(@config_sources)
          }
        end
      rescue ConfigurationError => e
        {
          ok: false,
          status: e.http_status,
          error_code: e.error_code,
          duration_ms: elapsed_ms(started),
          host: safe_host(@api_base_url),
          config_sources: self.class.safe_config_sources(e.config_sources)
        }
      end

      def self.resolve_credentials
        sources = { api_url_source: 'missing', api_key_source: 'missing', api_key_configured: false }

        api_base_url, api_url_source = resolve_api_url
        api_key, api_key_source = resolve_api_key

        sources[:api_url_source] = api_url_source
        sources[:api_key_source] = api_key_source
        sources[:api_key_configured] = api_key.present?

        {
          api_base_url: normalize_api_base_url(api_base_url),
          api_key: api_key,
          sources: sources
        }
      end

      def self.resolve_api_url
        db_url = strip_value(GlobalConfig.get('EVOLUTION_API_URL')['EVOLUTION_API_URL'])
        return [db_url, 'global_config_api_url'] if db_url.present?

        env_url = strip_value(ENV.fetch('EVOLUTION_API_URL', nil))
        return [env_url, 'env_api_url'] if env_url.present?

        ['', 'missing']
      end

      def self.resolve_api_key
        db_key = strip_value(GlobalConfig.get('EVOLUTION_API_KEY')['EVOLUTION_API_KEY'])
        return [db_key, 'global_config_api_key'] if db_key.present?

        env_key = strip_value(ENV.fetch('EVOLUTION_API_KEY', nil))
        return [env_key, 'env_api_key'] if env_key.present?

        ['', 'missing']
      end

      def self.configured?
        resolution = resolve_credentials
        resolution[:api_base_url].present? && resolution[:api_key].present? && valid_api_url?(resolution[:api_base_url])
      end

      def self.pairing_code_supported?
        ActiveModel::Type::Boolean.new.cast(
          ENV.fetch('EVOLUTION_PAIRING_CODE_SUPPORTED', GlobalConfig.get('EVOLUTION_PAIRING_CODE_SUPPORTED')['EVOLUTION_PAIRING_CODE_SUPPORTED'])
        )
      rescue StandardError
        false
      end

      def self.strip_value(value)
        value.to_s.strip.presence
      end

      def self.normalize_api_base_url(url)
        base = strip_value(url)
        return '' if base.blank?

        base.chomp('/')
      end

      def self.valid_api_url?(url)
        uri = URI.parse(url.to_s)
        uri.is_a?(URI::HTTP) && uri.host.present?
      rescue URI::InvalidURIError
        false
      end

      def self.safe_config_sources(sources)
        sources ||= {}
        {
          api_url_source: sources[:api_url_source],
          api_key_source: sources[:api_key_source],
          api_key_configured: sources[:api_key_configured]
        }
      end

      def self.log_configuration_failure(error:)
        Rails.logger.warn(
          {
            event: 'evolution_configuration_error',
            error_code: error.error_code,
            error_class: error.class.name,
            message: error.message,
            config_sources: safe_config_sources(error.config_sources)
          }.to_json
        )
      end

      private

      def validate_configuration!(resolution)
        sources = resolution[:sources]

        if resolution[:api_base_url].blank?
          raise ConfigurationError.new(
            'Evolution API URL not configured',
            error_code: Errors::ERROR_CODES[:not_configured],
            config_sources: sources
          )
        end

        unless self.class.valid_api_url?(resolution[:api_base_url])
          raise ConfigurationError.new(
            'Evolution API URL is invalid',
            error_code: Errors::ERROR_CODES[:invalid_url],
            config_sources: sources
          )
        end

        return if resolution[:api_key].present?

        raise ConfigurationError.new(
          'Evolution API key not configured',
          error_code: Errors::ERROR_CODES[:not_configured],
          config_sources: sources
        )
      end

      def request_json(method, path, query: {}, body: nil)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        url = request_url(path)
        response = perform_http(method, url, query: query, body: body)
        duration_ms = elapsed_ms(started)
        result = parse_json_response(response)

        log_request(path: path, status: result[:status], duration_ms: duration_ms, error: result[:error])
        result
      rescue Net::OpenTimeout, Net::ReadTimeout
        timeout_result
      rescue SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, HTTParty::Error => e
        upstream_unavailable_result(e)
      end

      def perform_http(method, url, query:, body:)
        options = {
          query: query,
          headers: auth_headers,
          timeout: DEFAULT_TIMEOUT
        }
        options[:body] = body.to_json if body
        options[:headers] = auth_headers.merge('Content-Type' => 'application/json') if body

        case method
        when :get then self.class.get(url, options)
        when :post then self.class.post(url, options)
        when :delete then self.class.delete(url, options)
        else
          raise ArgumentError, "Unsupported HTTP method: #{method}"
        end
      end

      def request_url(path)
        normalized_path = path.start_with?('/') ? path : "/#{path}"
        "#{@api_base_url}#{normalized_path}"
      end

      def auth_headers
        {
          'apikey' => @api_key,
          'Accept' => 'application/json'
        }
      end

      def encoded_instance_name(instance_name)
        ERB::Util.url_encode(instance_name.to_s)
      end

      def parse_json_response(response)
        unless response.success?
          return error_result(
            extract_error_detail(response),
            status: response.code,
            error_code: Errors.error_code_for_status(response.code)
          )
        end

        parsed = response.parsed_response
        { data: sanitize_payload(parsed), status: response.code }
      rescue JSON::ParserError
        error_result(
          'Evolution API returned invalid JSON payload',
          status: 502,
          error_code: Errors::ERROR_CODES[:invalid_response]
        )
      end

      def sanitize_payload(payload)
        case payload
        when Hash
          payload.deep_dup.tap { |copy| strip_sensitive_keys!(copy) }
        when Array
          payload.map { |item| item.is_a?(Hash) ? sanitize_payload(item) : item }
        else
          payload
        end
      end

      def strip_sensitive_keys!(hash)
        return unless hash.is_a?(Hash)

        SENSITIVE_RESPONSE_KEYS.each do |key|
          hash.delete(key)
          hash.delete(key.to_sym)
        end

        hash.each_value do |value|
          strip_sensitive_keys!(value) if value.is_a?(Hash)
          value.each { |item| strip_sensitive_keys!(item) } if value.is_a?(Array)
        end
      end

      def error_result(message, status:, error_code:)
        { error: message, status: status, error_code: error_code }
      end

      def timeout_result
        error_result('Evolution API request timeout', status: 504, error_code: Errors::ERROR_CODES[:timeout])
      end

      def upstream_unavailable_result(error)
        error_result(
          'Evolution API upstream unavailable',
          status: 502,
          error_code: Errors::ERROR_CODES[:upstream_unavailable]
        ).tap do
          Rails.logger.warn({ event: 'evolution_upstream_error', error_class: error.class.name }.to_json)
        end
      end

      def extract_error_detail(response)
        parsed = response.parsed_response
        return parsed['message'] if parsed.is_a?(Hash) && parsed['message'].present?
        return parsed['error'] if parsed.is_a?(Hash) && parsed['error'].present?

        response.message.presence || 'Evolution API request failed'
      end

      def log_request(path:, status:, duration_ms:, error: nil)
        Rails.logger.info(
          {
            event: 'evolution_api_request',
            path: path,
            status: status,
            duration_ms: duration_ms,
            error_present: error.present?,
            config_api_url_source: @config_sources[:api_url_source],
            config_api_key_source: @config_sources[:api_key_source]
          }.to_json
        )
      end

      def safe_host(url)
        URI.parse(url.to_s).host
      rescue URI::InvalidURIError
        nil
      end

      def elapsed_ms(started)
        ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round
      end
    end
  end
end
