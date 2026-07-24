# frozen_string_literal: true

module Optimia
  module ChannelManager
    class MissingInboxHandler
      def initialize(connection:, performed_by: nil)
        @connection = connection
        @performed_by = performed_by
      end

      def perform!
        return skip_result('recreation_disabled') unless @connection.inbox_recreation_allowed?

        if auto_repair_enabled?
          ProvisioningService.new(connection: @connection, performed_by: @performed_by).perform!
          @connection.update!(last_reconciled_at: Time.current)
          notify_inconsistent(repaired: true)
          return { status: 'repaired' }
        end

        notify_inconsistent(repaired: false)
        { status: 'inconsistent' }
      end

      private

      def auto_repair_enabled?
        raw = ENV.fetch('OPTIMIA_AUTO_REPAIR_MISSING_INBOX', 'true')
        ActiveModel::Type::Boolean.new.cast(raw)
      end

      def notify_inconsistent(repaired:)
        ConnectionAlertService.new(connection: @connection).notify!(
          alert_type: 'inbox_inconsistent',
          message: I18n.t('optimia.whatsapp_connections.alerts.inbox_inconsistent'),
          metadata: { repaired: repaired }
        )
      end

      def skip_result(reason)
        { status: 'skipped', reason: reason }
      end
    end
  end
end
