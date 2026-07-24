# frozen_string_literal: true

class EnableOptimiaChannelManagerForExistingAccounts < ActiveRecord::Migration[7.1]
  def up
    Account.find_in_batches(batch_size: 100) do |accounts|
      accounts.each { |account| account.enable_features!('optimia_channel_manager') }
    end
  end
end
