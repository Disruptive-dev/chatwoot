# frozen_string_literal: true

require_relative 'errors'

module Integrations
  module SpectraFlow
    class Client
      include HTTParty

      DEFAULT_TIMEOUT = 15
      MAX_DOWNLOAD_BYTES = 40 * 1024 * 1024
      SENDABLE_PATH = '/api/optimia/documents/sendable'
      SENSITIVE_KEYS = %w[
        tenant_id storage_path file_path provider download_url
        created_by internal_id expires_at
      ].freeze
      DOWNLOAD_TOKEN_KEYS = %w[token item_id expires_at].freeze

      def initialize(account:)
        @account = account
        resolution = self.class.resolve_credentials(account)
        @config_sources = resolution[:sources]
        @api_base_url = resolution[:api_base_url]
        @bearer_token = resolution[:bearer_token]

        validate_configuration!(resolution)
      end

      def list_sendable(q: '', category: '', tag: '', limit: 100)
        request_json(:get, SENDABLE_PATH, query: {
                       q: q,
                       category: category,
                       tag: tag,
                       limit: limit
                     })
      end

      def create_download_token(item_id)
        cleaned_id = item_id.to_s.strip
        unless cleaned_id.match?(/\A[\w-]+\z/)
          return error_result('Invalid document id', status: 422, error_code: 'invalid_document_id')
        end

        request_json(:post, "/api/optimia/documents/#{cleaned_id}/download-token", body: {}, sanitize: :download_token)
      end

      def download(item_id, token)
        cleaned_id = item_id.to_s.strip
        cleaned_token = token.to_s.strip
        if cleaned_id.blank? || cleaned_token.blank?
          return error_result('Invalid download request', status: 422, error_code: 'invalid_download_request')
        end

        request_download("/api/optimia/documents/#{cleaned_id}/download", query: { token: cleaned_token })
      end

      def health_check
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        host = safe_host(@api_base_url)

        result = list_sendable(limit: 1)
        duration_ms = elapsed_ms(started)

        if result[:error].present?
          {
            ok: false,
            status: result[:status],
            error_code: result[:error_code],
            duration_ms: duration_ms,
            host: host,
            path: SENDABLE_PATH,
            config_sources: safe_config_sources(@config_sources)
          }
        else
          {
            ok: true,
            status: 200,
            error_code: nil,
            duration_ms: duration_ms,
            host: host,
            path: SENDABLE_PATH,
            config_sources: safe_config_sources(@config_sources)
          }
        end
      rescue ConfigurationError => e
        {
          ok: false,
          status: e.http_status,
          error_code: e.error_code,
          duration_ms: elapsed_ms(started),
          host: host,
          path: SENDABLE_PATH,
          config_sources: safe_config_sources(e.config_sources),
          error_class: e.class.name
        }
      end

      def self.credentials_for(account)
        resolve_credentials(account).slice(:api_base_url, :bearer_token)
      end

      def self.resolve_credentials(account)
        attrs = account.custom_attributes || {}
        sources = {
          api_url_source: 'missing',
          token_source: 'missing',
          token_configured: false
        }

        api_base_url, api_url_source = resolve_api_url(attrs)
        bearer_token, token_source = resolve_bearer_token(attrs)

        sources[:api_url_source] = api_url_source
        sources[:token_source] = token_source
        sources[:token_configured] = bearer_token.present?

        {
          api_base_url: normalize_api_base_url(api_base_url),
          bearer_token: normalize_bearer_token(bearer_token),
          sources: sources
        }
      end

      def self.resolve_api_url(attrs)
        account_url = strip_value(attrs['spectra_flow_api_url'])
        return [account_url, 'account_custom_attributes'] if account_url.present?

        db_url = strip_value(GlobalConfig.get('SPECTRA_FLOW_API_URL')['SPECTRA_FLOW_API_URL'])
        return [db_url, 'global_config_api_url'] if db_url.present?

        env_url = strip_value(ENV.fetch('SPECTRA_FLOW_API_URL', nil))
        return [env_url, 'env_api_url'] if env_url.present?

        ['', 'missing']
      end

      def self.resolve_bearer_token(attrs)
        account_token = strip_value(attrs['spectra_flow_bearer_token'])
        return [account_token, 'account_custom_attributes'] if account_token.present?

        db_inbox = strip_value(GlobalConfig.get('SPECTRA_FLOW_INBOX_BEARER_TOKEN')['SPECTRA_FLOW_INBOX_BEARER_TOKEN'])
        return [db_inbox, 'global_config_inbox_token'] if db_inbox.present?

        env_inbox = strip_value(ENV.fetch('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil))
        return [env_inbox, 'env_inbox_token'] if env_inbox.present?

        db_api = strip_value(GlobalConfig.get('SPECTRA_FLOW_API_TOKEN')['SPECTRA_FLOW_API_TOKEN'])
        return [db_api, 'global_config_api_token'] if db_api.present?

        env_api = strip_value(ENV.fetch('SPECTRA_FLOW_API_TOKEN', nil))
        return [env_api, 'env_api_token'] if env_api.present?

        ['', 'missing']
      end

      def self.strip_value(value)
        value.to_s.strip.presence
      end

      def self.normalize_api_base_url(url)
        base = strip_value(url)
        return '' if base.blank?

        base = base.chomp('/')
        base = base.sub(%r{/api\z}i, '') if base.match?(%r{/api\z}i)
        base.chomp('/')
      end

      def self.normalize_bearer_token(token)
        value = strip_value(token)
        return '' if value.blank?

        value.sub(/\Abearer\s+/i, '')
      end

      def self.valid_api_url?(url)
        uri = URI.parse(url.to_s)
        uri.is_a?(URI::HTTP) && uri.host.present?
      rescue URI::InvalidURIError
        false
      end

      def self.sanitize_filename(name)
        decoded = URI.decode_www_form_component(name.to_s)
        base = File.basename(decoded)
        sanitized = base.gsub(/[^\w\s\-.áéíóúñÁÉÍÓÚÑüÜ()]/, '_').squeeze('_').strip
        sanitized.presence || 'documento'
      end

      def self.log_configuration_failure(account:, error:)
        Rails.logger.warn(
          {
            event: 'spectra_flow_configuration_error',
            account_id: account.id,
            error_code: error.error_code,
            error_class: error.class.name,
            message: error.message,
            config_sources: safe_config_sources(error.config_sources)
          }.to_json
        )
      end

      def self.safe_config_sources(sources)
        sources ||= {}
        {
          api_url_source: sources[:api_url_source],
          token_source: sources[:token_source],
          token_configured: sources[:token_configured]
        }
      end

      private

      def validate_configuration!(resolution)
        sources = resolution[:sources]

        if resolution[:api_base_url].blank?
          raise ConfigurationError.new(
            'Spectra Flow API URL not configured',
            error_code: Errors::ERROR_CODES[:not_configured],
            config_sources: sources
          )
        end

        unless self.class.valid_api_url?(resolution[:api_base_url])
          raise ConfigurationError.new(
            'Spectra Flow API URL is invalid',
            error_code: Errors::ERROR_CODES[:invalid_url],
            config_sources: sources
          )
        end

        if resolution[:bearer_token].blank?
          raise ConfigurationError.new(
            'Spectra Flow bearer token not configured',
            error_code: Errors::ERROR_CODES[:not_configured],
            config_sources: sources
          )
        end
      end

      def request_json(method, path, query: {}, body: nil, sanitize: :default)
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        url = request_url(path)
        host = safe_host(@api_base_url)

        response = perform_http(method, url, query: query, body: body)
        duration_ms = elapsed_ms(started)
        result = parse_json_response(response, sanitize: sanitize)

        log_request(
          host: host,
          path: path,
          status: result[:status],
          duration_ms: duration_ms,
          error_class: result[:error].present? ? 'UpstreamError' : nil,
          document_id: extract_document_id(path)
        )

        result
      rescue Net::OpenTimeout, Net::ReadTimeout
        duration_ms = elapsed_ms(started)
        log_request(host: safe_host(@api_base_url), path: path, status: 504, duration_ms: duration_ms, error_class: 'TimeoutError')
        timeout_result
      rescue SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError, HTTParty::Error => e
        duration_ms = elapsed_ms(started)
        log_request(host: safe_host(@api_base_url), path: path, status: 502, duration_ms: duration_ms, error_class: e.class.name)
        upstream_unavailable_result(e)
      end

      def request_download(path, query: {})
        started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        url = request_url(path)

        response = self.class.get(
          url,
          query: query,
          headers: download_headers,
          format: :plain,
          timeout: DEFAULT_TIMEOUT
        )

        duration_ms = elapsed_ms(started)
        result = parse_download_response(response)
        log_request(
          host: safe_host(@api_base_url),
          path: path,
          status: result[:status],
          duration_ms: duration_ms,
          document_id: extract_document_id(path),
          mime_type: result.dig(:data, :content_type),
          file_size: result.dig(:data, :body)&.bytesize,
          filename: result.dig(:data, :filename)
        )
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
          'Authorization' => "Bearer #{@bearer_token}",
          'Accept' => 'application/json'
        }
      end

      def download_headers
        {
          'Authorization' => "Bearer #{@bearer_token}",
          'Accept' => '*/*'
        }
      end

      def parse_json_response(response, sanitize: :default)
        unless response.success?
          return error_result(
            extract_error_detail(response),
            status: response.code,
            error_code: Errors.error_code_for_status(response.code)
          )
        end

        parsed = response.parsed_response
        unless parsed.is_a?(Hash) || parsed.is_a?(Array)
          return error_result(
            'Spectra Flow returned invalid JSON payload',
            status: 502,
            error_code: Errors::ERROR_CODES[:invalid_response]
          )
        end

        { data: sanitize_payload(parsed, mode: sanitize), status: response.code }
      rescue JSON::ParserError
        error_result(
          'Spectra Flow returned invalid JSON payload',
          status: 502,
          error_code: Errors::ERROR_CODES[:invalid_response]
        )
      end

      def parse_download_response(response)
        if response.success?
          body = response.body.to_s
          if body.bytesize > MAX_DOWNLOAD_BYTES
            return error_result('File exceeds maximum allowed size', status: 422, error_code: 'file_too_large')
          end

          filename = self.class.sanitize_filename(extract_filename(response.headers['content-disposition']))
          {
            data: {
              body: body,
              content_type: response.headers['content-type'] || 'application/octet-stream',
              filename: filename
            },
            status: response.code
          }
        else
          error_result(
            extract_error_detail(response),
            status: response.code,
            error_code: Errors.error_code_for_status(response.code)
          )
        end
      end

      def error_result(message, status:, error_code:)
        {
          error: message,
          status: status,
          error_code: error_code
        }
      end

      def timeout_result
        error_result(
          'Spectra Flow request timeout',
          status: 504,
          error_code: Errors::ERROR_CODES[:timeout]
        )
      end

      def upstream_unavailable_result(error)
        error_result(
          'Spectra Flow upstream unavailable',
          status: 502,
          error_code: Errors::ERROR_CODES[:upstream_unavailable]
        ).tap do |result|
          Rails.logger.warn(
            {
              event: 'spectra_flow_upstream_error',
              account_id: @account.id,
              error_class: error.class.name
            }.to_json
          )
        end
      end

      def log_request(host:, path:, status:, duration_ms:, error_class: nil, document_id: nil, mime_type: nil, file_size: nil, filename: nil)
        Rails.logger.info(
          {
            event: 'spectra_flow_request',
            account_id: @account.id,
            host: host,
            path: path,
            status: status,
            duration_ms: duration_ms,
            error_class: error_class,
            document_id: document_id,
            mime_type: mime_type,
            file_size: file_size,
            filename: filename,
            config_api_url_source: @config_sources[:api_url_source],
            config_token_source: @config_sources[:token_source],
            token_configured: @config_sources[:token_configured]
          }.compact.to_json
        )
      end

      def sanitize_payload(payload, mode: :default)
        case payload
        when Hash
          if mode == :download_token
            return payload.slice(*DOWNLOAD_TOKEN_KEYS)
          end

          payload.deep_dup.tap do |copy|
            strip_sensitive_keys!(copy)
            sanitize_items!(copy)
          end
        when Array
          payload.map { |item| sanitize_document_item(item) }
        else
          payload
        end
      end

      def sanitize_items!(hash)
        %w[items documents].each do |key|
          next unless hash[key].is_a?(Array)

          hash[key] = hash[key].map { |item| sanitize_document_item(item) }
        end
      end

      def sanitize_document_item(item)
        return item unless item.is_a?(Hash)

        item.each_with_object({}) do |(key, value), sanitized|
          key_s = key.to_s
          next if SENSITIVE_KEYS.include?(key_s)

          sanitized[key] = value
        end
      end

      def strip_sensitive_keys!(hash)
        hash.delete('tenant_id')
        hash.delete(:tenant_id)
        SENSITIVE_KEYS.each do |key|
          hash.delete(key)
          hash.delete(key.to_sym)
        end
      end

      def extract_error_detail(response)
        parsed = response.parsed_response
        return parsed['detail'] if parsed.is_a?(Hash) && parsed['detail'].present?
        return parsed['error'] if parsed.is_a?(Hash) && parsed['error'].present?

        response.message.presence || 'Spectra Flow request failed'
      end

      def extract_filename(content_disposition)
        return 'documento' if content_disposition.blank?

        match = content_disposition.match(/filename\*=UTF-8''([^;]+)/i)
        return URI.decode_www_form_component(match[1].strip) if match

        match = content_disposition.match(/filename="([^"]+)"/i)
        return match[1].strip if match

        match = content_disposition.match(/filename=([^;]+)/i)
        (match && match[1]) ? match[1].strip.delete('"') : 'documento'
      end

      def extract_document_id(path)
        match = path.to_s.match(%r{/documents/([\w-]+)})
        match ? match[1] : nil
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
