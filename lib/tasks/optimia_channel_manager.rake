# frozen_string_literal: true

namespace :optimia do
  namespace :channel_manager do
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
