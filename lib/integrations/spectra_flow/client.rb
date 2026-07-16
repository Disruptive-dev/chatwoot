# frozen_string_literal: true

module Integrations
  module SpectraFlow
    class Client
      include HTTParty

      class ConfigurationError < StandardError; end

      DEFAULT_TIMEOUT = 15
      MAX_DOWNLOAD_BYTES = 40 * 1024 * 1024
      SENSITIVE_KEYS = %w[
        tenant_id storage_path file_path provider download_url
        created_by internal_id token expires_at
      ].freeze

      def initialize(account:)
        @account = account
        @api_base_url = credentials[:api_base_url].to_s.chomp('/')
        @bearer_token = credentials[:bearer_token].to_s

        raise ConfigurationError, 'Spectra Flow API URL not configured' if @api_base_url.blank?
        raise ConfigurationError, 'Spectra Flow bearer token not configured' if @bearer_token.blank?
        raise ConfigurationError, 'Spectra Flow API URL is invalid' unless self.class.valid_api_url?(@api_base_url)
      end

      def list_sendable(q: '', category: '', tag: '', limit: 100)
        get_json(
          '/api/optimia/documents/sendable',
          query: {
            q: q,
            category: category,
            tag: tag,
            limit: limit
          }
        )
      end

      def create_download_token(item_id)
        cleaned_id = item_id.to_s.strip
        unless cleaned_id.match?(/\A[\w-]+\z/)
          return { error: 'Invalid document id', status: 422 }
        end

        post_json("/api/optimia/documents/#{cleaned_id}/download-token", {})
      end

      def download(item_id, token)
        cleaned_id = item_id.to_s.strip
        cleaned_token = token.to_s.strip
        if cleaned_id.blank? || cleaned_token.blank?
          return { error: 'Invalid download request', status: 422 }
        end

        response = self.class.get(
          "#{@api_base_url}/api/optimia/documents/#{cleaned_id}/download",
          query: { token: cleaned_token },
          headers: auth_headers,
          format: :plain,
          timeout: DEFAULT_TIMEOUT
        )

        parse_download_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout, HTTParty::Error, SocketError, Errno::ECONNREFUSED
        { error: 'Spectra Flow request timeout', status: 502 }
      end

      def self.credentials_for(account)
        attrs = account.custom_attributes || {}

        bearer_token = attrs['spectra_flow_bearer_token'].presence ||
                       GlobalConfigService.load('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).presence ||
                       GlobalConfigService.load('SPECTRA_FLOW_API_TOKEN', nil).presence ||
                       ENV.fetch('SPECTRA_FLOW_INBOX_BEARER_TOKEN', nil).presence ||
                       ENV.fetch('SPECTRA_FLOW_API_TOKEN', nil)

        {
          api_base_url: attrs['spectra_flow_api_url'].presence ||
            GlobalConfigService.load('SPECTRA_FLOW_API_URL', ENV.fetch('SPECTRA_FLOW_API_URL', nil)),
          bearer_token: bearer_token
        }
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

      private

      def credentials
        self.class.credentials_for(@account)
      end

      def auth_headers
        {
          'Authorization' => "Bearer #{@bearer_token}",
          'Accept' => 'application/json'
        }
      end

      def get_json(path, query: {})
        response = self.class.get(
          "#{@api_base_url}#{path}",
          query: query,
          headers: auth_headers,
          timeout: DEFAULT_TIMEOUT
        )

        parse_json_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout, HTTParty::Error, SocketError, Errno::ECONNREFUSED
        { error: 'Spectra Flow request timeout', status: 502 }
      end

      def post_json(path, body)
        response = self.class.post(
          "#{@api_base_url}#{path}",
          headers: auth_headers.merge('Content-Type' => 'application/json'),
          body: body.to_json,
          timeout: DEFAULT_TIMEOUT
        )

        parse_json_response(response)
      rescue Net::OpenTimeout, Net::ReadTimeout, HTTParty::Error, SocketError, Errno::ECONNREFUSED
        { error: 'Spectra Flow request timeout', status: 502 }
      end

      def parse_json_response(response)
        if response.success?
          { data: sanitize_payload(response.parsed_response), status: response.code }
        else
          detail = extract_error_detail(response)
          { error: detail, status: response.code }
        end
      rescue StandardError
        { error: 'Spectra Flow request failed', status: 502 }
      end

      def parse_download_response(response)
        if response.success?
          body = response.body.to_s
          if body.bytesize > MAX_DOWNLOAD_BYTES
            return { error: 'File exceeds maximum allowed size', status: 422 }
          end

          filename = self.class.sanitize_filename(
            extract_filename(response.headers['content-disposition'])
          )
          {
            data: {
              body: body,
              content_type: response.headers['content-type'] || 'application/octet-stream',
              filename: filename
            },
            status: response.code
          }
        else
          detail = extract_error_detail(response)
          { error: detail, status: response.code }
        end
      rescue StandardError
        { error: 'Spectra Flow request failed', status: 502 }
      end

      def sanitize_payload(payload)
        case payload
        when Hash
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

        match = content_disposition.match(/filename\*?=(?:UTF-8''|")?([^";]+)/i)
        (match && match[1]) ? match[1].strip : 'documento'
      end
    end
  end
end
