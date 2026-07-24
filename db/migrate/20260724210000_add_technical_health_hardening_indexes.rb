# frozen_string_literal: true

class AddTechnicalHealthHardeningIndexes < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :optimia_technical_alerts,
              :alert_type,
              unique: true,
              where: "status = 'open'",
              name: 'index_optimia_technical_alerts_unique_open',
              algorithm: :concurrently

    add_index :optimia_technical_timeline_events,
              %i[optimia_channel_connection_id occurred_at],
              name: 'index_optimia_technical_timeline_on_connection_and_time',
              algorithm: :concurrently
  end
end
