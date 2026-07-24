# frozen_string_literal: true

namespace :optimia do
  namespace :channel_manager do
    desc 'List monitorable connections with masked diagnostics'
    task list_connections: :environment do
      OptimiaChannelConnection.monitorable.find_each do |connection|
        puts Optimia::ChannelManager::HealthMonitorService.diagnose(connection: connection).to_json
      end
    end

    desc 'Diagnose a single connection (masked output)'
    task :diagnose, [:connection_id] => :environment do |_task, args|
      connection = OptimiaChannelConnection.find(args[:connection_id])
      puts Optimia::ChannelManager::HealthMonitorService.diagnose(connection: connection).to_json
    end

    desc 'Alias for diagnose'
    task :diagnose_outbound, [:connection_id] => :environment do |_task, args|
      Rake::Task['optimia:channel_manager:diagnose'].invoke(args[:connection_id])
    end

    desc 'Run health monitor once for all monitorable connections'
    task monitor_once: :environment do
      Optimia::ChannelManager::MonitorConnectionsJob.perform_now
      puts({ status: 'completed' }.to_json)
    end

    desc 'Verify Evolution instance state for a connection'
    task :verify_evolution, [:connection_id] => :environment do |_task, args|
      connection = OptimiaChannelConnection.find(args[:connection_id])
      client = Integrations::Evolution::Client.new
      result = client.connection_state(connection.external_instance_id)
      puts({
        connection_id: connection.id,
        account_id: connection.account_id,
        instance_name: connection.external_instance_id,
        status: result[:status],
        error_code: result[:error_code]
      }.to_json)
    end

    desc 'Health check for Evolution API configuration (no secrets printed)'
    task health: :environment do
      client = Integrations::Evolution::Client.new
      result = client.health_check
      puts result.to_json
      exit(result[:ok] ? 0 : 1)
    rescue Integrations::Evolution::ConfigurationError => e
      puts({ ok: false, error_code: e.error_code, message: e.message }.to_json)
      exit 1
    end

    desc 'Sync Evolution webhook_url into provisioned API inboxes (idempotent)'
    task sync_webhooks: :environment do
      scope = OptimiaChannelConnection.where(state: %w[connected syncing ready reconnecting degraded qr_required]).where.not(inbox_id: nil)
      results = scope.map do |connection|
        Optimia::ChannelManager::ChatwootWebhookSyncService.new(connection: connection).perform!
        { connection_id: connection.id, status: 'synced' }
      rescue Optimia::ChannelManager::ChatwootWebhookSyncService::SyncError => e
        { connection_id: connection.id, status: 'failed', error_code: e.error_code }
      end
      puts results.to_json
    end

    desc 'Enable optimia_channel_manager feature for all accounts (staging bootstrap)'
    task enable_feature: :environment do
      count = 0
      Account.find_in_batches(batch_size: 100) do |accounts|
        accounts.each do |account|
          account.enable_features!('optimia_channel_manager')
          count += 1
        end
      end
      puts "Enabled optimia_channel_manager for #{count} accounts"
    end
  end
end
