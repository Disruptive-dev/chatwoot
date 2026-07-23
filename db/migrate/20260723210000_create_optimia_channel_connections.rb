# frozen_string_literal: true

class CreateOptimiaChannelConnections < ActiveRecord::Migration[7.1]
  def change
    create_table :optimia_channel_connections do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :inbox, foreign_key: true, index: true
      t.string :provider, null: false, default: 'evolution'
      t.string :channel_type, null: false, default: 'whatsapp'
      t.string :display_name, null: false
      t.string :external_instance_id
      t.string :phone_number
      t.string :state, null: false, default: 'draft'
      t.jsonb :connection_metadata, null: false, default: {}
      t.text :encrypted_credentials
      t.datetime :qr_expires_at
      t.datetime :last_connected_at
      t.datetime :last_disconnected_at
      t.string :last_error_code
      t.string :last_error_message
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :updated_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :optimia_channel_connections, %i[provider external_instance_id],
              unique: true,
              where: 'external_instance_id IS NOT NULL',
              name: 'index_optimia_connections_on_provider_and_external_instance'
    add_index :optimia_channel_connections, %i[account_id phone_number],
              unique: true,
              where: 'phone_number IS NOT NULL',
              name: 'index_optimia_connections_on_account_and_phone'
    add_index :optimia_channel_connections, :state
  end
end
