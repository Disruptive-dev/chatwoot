# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      class ProviderAdapter
        ConnectionResult = Struct.new(:external_instance_id, :metadata, :credentials, keyword_init: true)
        QrResult = Struct.new(:base64, :expires_at, :pairing_code, keyword_init: true)
        StatusResult = Struct.new(:remote_state, :phone_number, :metadata, keyword_init: true)

        def provider_key
          raise NotImplementedError
        end

        def supports_pairing_code?
          false
        end

        def ensure_instance!(connection:)
          raise NotImplementedError
        end

        def fetch_qr!(connection:)
          raise NotImplementedError
        end

        def fetch_status!(connection:)
          raise NotImplementedError
        end

        def disconnect!(connection:)
          raise NotImplementedError
        end

        def configure_chatwoot!(connection:, chatwoot_config:)
          raise NotImplementedError
        end
      end
    end
  end
end
