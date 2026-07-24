# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      module Providers
        class EvolutionAdapter < ProviderAdapter
          REMOTE_STATE_MAP = {
            'open' => 'connected',
            'connecting' => 'waiting_scan',
            'close' => 'disconnected'
          }.freeze

          def provider_key
            'evolution'
          end

          def supports_pairing_code?
            Integrations::Evolution::Client.pairing_code_supported?
          end

          def ensure_instance!(connection:)
            client = build_client
            instance_name = connection.external_instance_id.presence || connection.generate_external_instance_id!

            existing = client.fetch_instances(instance_name: instance_name)
            return build_existing_result(instance_name, existing) if instance_exists?(existing, instance_name)

            created = client.create_instance(instance_name: instance_name, qrcode: true)
            raise_upstream_error!(created) if created[:error].present?

            payload = extract_instance_payload(created[:data], instance_name)
            credentials = extract_credentials(created[:data])

            ConnectionResult.new(
              external_instance_id: instance_name,
              metadata: {
                integration: 'WHATSAPP-BAILEYS',
                remote_state: payload[:state],
                instance_created_at: Time.current.iso8601
              },
              credentials: credentials
            )
          end

          def fetch_qr!(connection:)
            client = build_client
            instance_name = connection.external_instance_id
            raise ArgumentError, 'External instance missing' if instance_name.blank?

            response = client.connect_instance(instance_name)
            raise_upstream_error!(response) if response[:error].present?

            qr_payload = extract_qr_payload(response[:data])
            QrResult.new(
              base64: qr_payload[:base64],
              expires_at: Integrations::Evolution::Client::QR_TTL_SECONDS.seconds.from_now,
              pairing_code: qr_payload[:pairing_code]
            )
          end

          def fetch_status!(connection:)
            client = build_client
            instance_name = connection.external_instance_id
            raise ArgumentError, 'External instance missing' if instance_name.blank?

            response = client.connection_state(instance_name)
            raise_upstream_error!(response) if response[:error].present?

            payload = response[:data]
            instance_data = extract_instance_hash(payload)
            remote_state = extract_remote_state(instance_data, payload)
            phone_number = extract_phone_number(instance_data, payload)

            StatusResult.new(
              remote_state: remote_state,
              phone_number: phone_number,
              metadata: {
                mapped_state: REMOTE_STATE_MAP[remote_state.to_s],
                checked_at: Time.current.iso8601
              }
            )
          end

          def disconnect!(connection:)
            client = build_client
            instance_name = connection.external_instance_id
            return { success: true } if instance_name.blank?

            response = client.logout_instance(instance_name)
            raise_upstream_error!(response) if response[:error].present?

            { success: true }
          end

          def delete_instance!(connection:)
            client = build_client
            instance_name = connection.external_instance_id
            return { success: true } if instance_name.blank?

            response = client.delete_instance(instance_name)
            return { success: true } if response[:error].blank?
            return { success: true } if response[:status].to_i == 404

            raise_upstream_error!(response)
          end

          def configure_chatwoot!(connection:, chatwoot_config:)
            client = build_client
            instance_name = connection.external_instance_id
            raise ArgumentError, 'External instance missing' if instance_name.blank?

            response = client.set_chatwoot(instance_name, chatwoot_config: chatwoot_config)
            raise_upstream_error!(response) if response[:error].present?

            log_chatwoot_configuration(connection: connection, instance_name: instance_name, response: response)

            {
              success: true,
              status: response[:status],
              data: response[:data]
            }
          end

          private

          def build_client
            Integrations::Evolution::Client.new
          rescue Integrations::Evolution::ConfigurationError => e
            Integrations::Evolution::Client.log_configuration_failure(error: e)
            raise
          end

          def instance_exists?(response, instance_name)
            return false if response[:error].present?

            data = response[:data]
            return data.any? { |item| instance_name_for(item) == instance_name } if data.is_a?(Array)
            return instance_name_for(data) == instance_name if data.is_a?(Hash)

            false
          end

          def build_existing_result(instance_name, response)
            payload = if response[:data].is_a?(Array)
                        response[:data].find { |item| instance_name_for(item) == instance_name } || {}
                      else
                        response[:data] || {}
                      end

            ConnectionResult.new(
              external_instance_id: instance_name,
              metadata: {
                integration: 'WHATSAPP-BAILEYS',
                remote_state: payload['connectionStatus'] || payload['state'],
                recovered: true
              },
              credentials: {}
            )
          end

          def extract_instance_payload(data, instance_name)
            record = if data.is_a?(Array)
                       data.find { |item| instance_name_for(item) == instance_name } || data.first || {}
                     else
                       data || {}
                     end

            instance = record['instance'] || record
            { state: instance['status'] || instance['state'] || record['state'] }
          end

          def extract_credentials(data)
            record = data.is_a?(Array) ? data.first : data
            return {} unless record.is_a?(Hash)

            token = record['hash'] || record['token'] || record.dig('instance', 'token')
            token.present? ? { 'instance_token' => token } : {}
          end

          def extract_qr_payload(data)
            return { base64: nil, pairing_code: nil } unless data.is_a?(Hash)

            qr = data['qrcode'] || data['qr'] || data
            base64 = qr['base64'] || data['base64']
            base64 = "data:image/png;base64,#{base64}" if base64.present? && !base64.start_with?('data:')

            {
              base64: base64,
              pairing_code: qr['pairingCode'] || qr['pairing_code'] || data['pairingCode']
            }
          end

          def extract_phone_number(instance_data, payload)
            owner = instance_data['owner'] || payload['owner'] || instance_data['wuid']
            return normalize_phone(owner) if owner.present?

            normalize_phone(instance_data['phoneNumber'] || payload['phoneNumber'])
          end

          def extract_instance_hash(payload)
            return {} unless payload.is_a?(Hash)

            payload['instance'].presence || payload
          end

          def extract_remote_state(instance_data, payload)
            state = instance_data['state'] ||
                    instance_data['status'] ||
                    instance_data['connectionStatus'] ||
                    payload['state'] ||
                    payload['status']
            state.to_s
          end

          def normalize_phone(value)
            return nil if value.blank?

            digits = value.to_s.gsub(/\D/, '')
            digits.present? ? "+#{digits}" : nil
          end

          def instance_name_for(item)
            return '' unless item.is_a?(Hash)

            item['name'] || item['instanceName'] || item.dig('instance', 'instanceName')
          end

          def raise_upstream_error!(response)
            raise Integrations::Evolution::ConfigurationError.new(
              response[:error],
              error_code: response[:error_code] || Integrations::Evolution::Errors::ERROR_CODES[:connection_failed],
              config_sources: {}
            )
          end

          def log_chatwoot_configuration(connection:, instance_name:, response:)
            Rails.logger.info(
              {
                event: 'optimia_evolution_chatwoot_configured',
                connection_id: connection.id,
                account_id: connection.account_id,
                instance_name: instance_name,
                provider: connection.provider,
                endpoint: '/chatwoot/set',
                status: response[:status],
                error_code: response[:error_code]
              }.compact.to_json
            )
          end
        end
      end
    end
  end
end
