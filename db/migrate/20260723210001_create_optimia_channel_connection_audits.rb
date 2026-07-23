# frozen_string_literal: true

class CreateOptimiaChannelConnectionAudits < ActiveRecord::Migration[7.1]
  def change
    create_table :optimia_channel_connection_audits do |t|
      t.references :optimia_channel_connection, null: false, foreign_key: true,
                                               index: { name: 'index_optimia_connection_audits_on_connection_id' }
      t.references :account, null: false, foreign_key: true, index: true
      t.references :performed_by, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.string :from_state
      t.string :to_state
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :optimia_channel_connection_audits, :action
    add_index :optimia_channel_connection_audits, :created_at
  end
end
