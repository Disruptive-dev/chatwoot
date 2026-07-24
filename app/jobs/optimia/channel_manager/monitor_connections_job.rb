# frozen_string_literal: true

module Optimia
  module ChannelManager
    class MonitorConnectionsJob < ApplicationJob
      queue_as :scheduled_jobs

      def perform
        return unless Integrations::Optimia::ChannelManager::MonitorConfig.monitoring_enabled?
        return unless Integrations::Optimia::ChannelManager::Feature.globally_enabled?

        OptimiaChannelConnection.monitorable.find_each do |connection|
          next unless Integrations::Optimia::ChannelManager::Feature.enabled_for_account?(connection.account)

          HealthMonitorService.new(connection: connection).perform!
        rescue StandardError => e
          Rails.logger.warn(
            {
              event: 'optimia_channel_monitor_job_connection_failed',
              connection_id: connection.id,
              account_id: connection.account_id,
              error_class: e.class.name
            }.to_json
          )
        end
      end
    end
  end
end
