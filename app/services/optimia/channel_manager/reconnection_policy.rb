# frozen_string_literal: true

module Optimia
  module ChannelManager
    class ReconnectionPolicy
      def initialize(connection:, alert_service: nil)
        @connection = connection
        @alert_service = alert_service || ConnectionAlertService.new(connection: connection)
        @max_attempts = Integrations::Optimia::ChannelManager::MonitorConfig.reconnect_max_attempts
      end

      def apply_from_status!(status)
        mapped = map_remote_state(status.remote_state)
        case mapped
        when 'connected'
          apply_open!(status)
        when 'waiting_scan'
          apply_temporarily_closed!
        when 'disconnected'
          apply_session_invalid!
        end
      end

      def apply_upstream_failure!(error_code:)
        from_state = @connection.state
        transition_with_audit!('degraded', action: 'connection_degraded', metadata: { error_code: error_code }) if @connection.can_transition_to?('degraded')

        @alert_service.notify!(
          alert_type: 'evolution_unavailable',
          message: I18n.t('optimia.whatsapp_connections.alerts.evolution_unavailable'),
          metadata: { error_code: error_code, from_state: from_state }
        )

        record_error!(error_code)
      end

      private

      def apply_open!(status)
        previous_state = @connection.state
        @connection.update!(phone_number: status.phone_number) if status.phone_number.present?
        @connection.update!(
          reconnect_attempts_count: 0,
          last_connected_at: Time.current,
          last_error_at: nil
        )
        @connection.clear_error!

        if %w[reconnecting degraded qr_required disconnected failed error].include?(previous_state)
          transition_with_audit!('ready', action: 'connection_recovered') if @connection.can_transition_to?('ready')
          @alert_service.notify!(
            alert_type: 'reconnect_succeeded',
            message: I18n.t('optimia.whatsapp_connections.alerts.reconnect_succeeded'),
            metadata: { from_state: previous_state }
          )
        elsif @connection.state != 'ready' && @connection.can_transition_to?('ready')
          transition_with_audit!('ready', action: 'connection_recovered')
        end
      end

      def apply_temporarily_closed!
        from_state = @connection.state
        return if %w[draft creating created waiting_qr waiting_scan pairing].include?(from_state)

        attempts = @connection.reconnect_attempts_count.to_i + 1
        @connection.update!(
          reconnect_attempts_count: attempts,
          recent_reconnect_count: @connection.recent_reconnect_count.to_i + 1
        )

        if attempts >= @max_attempts
          require_qr!(from_state: from_state)
          return
        end

        if @connection.can_transition_to?('reconnecting')
          transition_with_audit!('reconnecting', action: 'reconnect_started', metadata: { attempt: attempts })
          @alert_service.notify!(
            alert_type: 'reconnect_started',
            message: I18n.t('optimia.whatsapp_connections.alerts.reconnect_started'),
            metadata: { attempt: attempts }
          )
        end
      end

      def apply_session_invalid!
        require_qr!(from_state: @connection.state)
      end

      def require_qr!(from_state:)
        if @connection.can_transition_to?('qr_required')
          transition_with_audit!('qr_required', action: 'qr_required', metadata: { from_state: from_state })
        end

        @alert_service.notify!(
          alert_type: 'qr_required',
          message: I18n.t('optimia.whatsapp_connections.alerts.qr_required'),
          metadata: { from_state: from_state }
        )
      end

      def transition_with_audit!(new_state, action:, metadata: {})
        from_state = @connection.state
        return if from_state == new_state

        @connection.transition_to!(new_state)
        AuditLogger.log(
          connection: @connection,
          action: action,
          from_state: from_state,
          to_state: new_state,
          metadata: metadata
        )
        AuditLogger.log(
          connection: @connection,
          action: 'state_changed',
          from_state: from_state,
          to_state: new_state,
          metadata: metadata
        )
      end

      def record_error!(error_code)
        @connection.update!(
          last_error_code: error_code,
          last_error_at: Time.current
        )
      end

      def map_remote_state(remote_state)
        case remote_state.to_s
        when 'open' then 'connected'
        when 'connecting' then 'waiting_scan'
        when 'close' then 'disconnected'
        else remote_state.to_s
        end
      end
    end
  end
end
