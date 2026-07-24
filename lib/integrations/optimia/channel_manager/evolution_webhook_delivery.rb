# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      class EvolutionWebhookDelivery
        EVOLUTION_WEBHOOK_PATTERN = %r{/chatwoot/webhook/}i
        SUPPORTED_EVENTS = %w[message_created message_updated].freeze
        DEFAULT_TIMEOUT_SECONDS = 30

        class << self
          def evolution_webhook?(url)
            url.to_s.match?(EVOLUTION_WEBHOOK_PATTERN)
          end

          def execute(url, payload)
            new(url, payload).execute
          end
        end

        def initialize(url, payload)
          @url = url
          @payload = payload
        end

        def execute
          response = perform_request
          handle_success(response)
        rescue Net::OpenTimeout, Net::ReadTimeout, RestClient::Exceptions::OpenTimeout, RestClient::Exceptions::ReadTimeout => e
          handle_timeout(e)
        rescue SocketError, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
          handle_connection_failure(e)
        rescue RestClient::ExceptionWithResponse => e
          handle_http_error(e)
        rescue StandardError => e
          handle_unexpected_error(e)
        end

        private

        attr_reader :url, :payload

        def perform_request
          RestClient::Request.execute(
            method: :post,
            url: url,
            payload: payload.to_json,
            headers: { content_type: :json, accept: :json },
            timeout: webhook_timeout
          )
        end

        def handle_success(response)
          parsed_body = parse_response_body(response)
          remote_id = OutboundDeliveryResult.extract_remote_id(parsed_body)
          result = OutboundDeliveryResult.new(
            http_status: response.code,
            remote_id: remote_id,
            interpreted: remote_id.present? ? 'accepted_with_remote_id' : 'accepted'
          )

          persist_remote_id!(remote_id) if remote_id.present?
          log_delivery(result: result, error_class: nil, error_present: false)
          result
        end

        def handle_timeout(error)
          log_delivery(
            result: OutboundDeliveryResult.new(http_status: nil, remote_id: nil, interpreted: 'timeout_assumed_accepted'),
            error_class: error.class.name,
            error_present: true
          )
          OutboundDeliveryResult.new(http_status: nil, remote_id: nil, interpreted: 'timeout_assumed_accepted')
        end

        def handle_connection_failure(error)
          mark_message_failed!(error.message)
          log_delivery(
            result: OutboundDeliveryResult.new(http_status: nil, remote_id: nil, interpreted: 'connection_failed'),
            error_class: error.class.name,
            error_present: true
          )
        end

        def handle_http_error(error)
          status = error.http_code
          if client_error?(status)
            mark_message_failed!(extract_error_message(error))
          else
            log_delivery(
              result: OutboundDeliveryResult.new(http_status: status, remote_id: nil, interpreted: 'server_error_assumed_accepted'),
              error_class: error.class.name,
              error_present: true
            )
          end
        end

        def handle_unexpected_error(error)
          mark_message_failed!(error.message)
          log_delivery(
            result: OutboundDeliveryResult.new(http_status: nil, remote_id: nil, interpreted: 'unexpected_error'),
            error_class: error.class.name,
            error_present: true
          )
        end

        def client_error?(status)
          status.to_i.between?(400, 499)
        end

        def mark_message_failed!(error_message)
          return unless message

          ::Optimia::ChannelManager::OutboundStatusProcessor.new(
            message: message,
            status: 'failed',
            external_error: error_message
          ).perform!
        end

        def persist_remote_id!(remote_id)
          return unless message

          message.update!(source_id: remote_id) if message.source_id.blank?
        end

        def parse_response_body(response)
          return {} if response.body.blank?

          JSON.parse(response.body)
        rescue JSON::ParserError
          {}
        end

        def extract_error_message(error)
          parsed = JSON.parse(error.response.body)
          parsed['message'] || parsed['error'] || error.message
        rescue JSON::ParserError
          error.message
        end

        def message
          return if message_id.blank?

          @message ||= Message.find_by(id: message_id)
        end

        def message_id
          payload[:id]
        end

        def inbox_id
          message&.inbox_id
        end

        def account_id
          message&.account_id
        end

        def instance_name
          connection&.external_instance_id
        end

        def connection
          return @connection if defined?(@connection)

          @connection = OptimiaChannelConnection.find_by(inbox_id: inbox_id)
        end

        def webhook_timeout
          raw_timeout = ENV.fetch('OPTIMIA_EVOLUTION_WEBHOOK_TIMEOUT', nil).presence
          raw_timeout ||= GlobalConfig.get_value('OPTIMIA_EVOLUTION_WEBHOOK_TIMEOUT')
          timeout = raw_timeout.to_i
          timeout.positive? ? timeout : DEFAULT_TIMEOUT_SECONDS
        end

        def log_delivery(result:, error_class:, error_present:)
          return unless SUPPORTED_EVENTS.include?(payload[:event])

          Rails.logger.info(
            {
              event: 'optimia_evolution_outbound_delivery',
              message_id: message_id,
              source_id: message&.source_id,
              account_id: account_id,
              inbox_id: inbox_id,
              instance_name: instance_name,
              http_status: result.http_status,
              interpreted: result.interpreted,
              remote_id: result.remote_id,
              error_class: error_class,
              error_present: error_present
            }.compact.to_json
          )
        end
      end
    end
  end
end
