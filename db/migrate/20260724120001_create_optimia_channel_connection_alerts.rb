# frozen_string_literal: true

class CreateOptimiaChannelConnectionAlerts < ActiveRecord::Migration[7.1]
  def change
    create_table :optimia_channel_connection_alerts do |t|
      t.references :optimia_channel_connection, null: false, foreign_key: true, index: { name: 'index_optimia_alerts_on_connection_id' }
      t.references :account, null: false, foreign_key: true, index: true
      t.string :alert_type, null: false
      t.string :message, null: false
      t.jsonb :metadata, null: false, default: {}
      t.datetime :read_at

      t.timestamps
    end

    add_index :optimia_channel_connection_alerts, %i[account_id alert_type created_at],
              name: 'index_optimia_alerts_on_account_type_created'
  end
end
