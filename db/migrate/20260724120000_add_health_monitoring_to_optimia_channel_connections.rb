# frozen_string_literal: true

class AddHealthMonitoringToOptimiaChannelConnections < ActiveRecord::Migration[7.1]
  def change
    change_table :optimia_channel_connections, bulk: true do |t|
      t.datetime :last_seen_at
      t.datetime :last_state_change_at
      t.datetime :last_error_at
      t.integer :reconnect_attempts_count, null: false, default: 0
      t.integer :recent_reconnect_count, null: false, default: 0
      t.datetime :last_health_check_at
    end

    add_index :optimia_channel_connections, :last_health_check_at
  end
end
