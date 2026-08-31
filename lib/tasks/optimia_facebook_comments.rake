# frozen_string_literal: true

namespace :optimia do
  namespace :facebook_comments do
    desc 'Enable Facebook comments for an account and subscribe feed webhooks. Usage: optimia:facebook_comments:activate[account_id]'
    task :activate, [:account_id] => :environment do |_t, args|
      account_id = args[:account_id]
      abort 'Usage: rake optimia:facebook_comments:activate[ACCOUNT_ID]' if account_id.blank?

      account = Account.find(account_id)
      Integrations::Optimia::FacebookComments::Feature.enable_for_account!(account)

      channels = Channel::FacebookPage.where(account: account)
      channels.find_each do |channel|
        Optimia::FacebookComments::FeedSubscriptionService.new(channel: channel).perform
      end

      puts "Facebook comments enabled for account #{account.id} (#{account.name}). Channels subscribed: #{channels.count}"
    end
  end
end
