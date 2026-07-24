# frozen_string_literal: true

class AddLifecycleToOptimiaChannelConnections < ActiveRecord::Migration[7.1]
  def change
    change_table :optimia_channel_connections, bulk: true do |t|
      t.string :lifecycle_status, null: false, default: 'active'
      t.datetime :archived_at
      t.datetime :deleted_at
      t.datetime :deletion_requested_at
      t.datetime :deletion_completed_at
      t.string :deletion_error
      t.boolean :inbox_recreation_enabled, null: false, default: true
      t.datetime :last_reconciled_at
    end

    add_index :optimia_channel_connections, :lifecycle_status
    add_index :optimia_channel_connections, :inbox_recreation_enabled
  end
end
