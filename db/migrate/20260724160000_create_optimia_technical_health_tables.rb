# frozen_string_literal: true

class CreateOptimiaTechnicalHealthTables < ActiveRecord::Migration[7.1]
  def change
    create_table :optimia_technical_health_checks do |t|
      t.string :component, null: false
      t.string :status, null: false, default: 'unknown'
      t.integer :latency_ms, default: 0
      t.string :version
      t.integer :uptime_seconds
      t.integer :error_count, default: 0
      t.jsonb :metadata, default: {}
      t.datetime :checked_at, null: false
      t.timestamps
    end
    add_index :optimia_technical_health_checks, :component
    add_index :optimia_technical_health_checks, :status
    add_index :optimia_technical_health_checks, :checked_at
    add_index :optimia_technical_health_checks, %i[component checked_at]

    create_table :optimia_technical_alerts do |t|
      t.string :alert_type, null: false
      t.string :component, null: false
      t.string :severity, null: false, default: 'info'
      t.string :status, null: false, default: 'open'
      t.text :message
      t.jsonb :metadata, default: {}
      t.datetime :opened_at, null: false
      t.datetime :acknowledged_at
      t.datetime :resolved_at
      t.timestamps
    end
    add_index :optimia_technical_alerts, :alert_type
    add_index :optimia_technical_alerts, :component
    add_index :optimia_technical_alerts, :severity
    add_index :optimia_technical_alerts, :status
    add_index :optimia_technical_alerts, :opened_at

    create_table :optimia_technical_incidents do |t|
      t.string :component, null: false
      t.string :status, null: false, default: 'open'
      t.text :summary
      t.text :root_cause
      t.text :action_taken
      t.string :responsible
      t.datetime :started_at, null: false
      t.datetime :detected_at
      t.datetime :acknowledged_at
      t.datetime :resolved_at
      t.integer :duration_seconds
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :optimia_technical_incidents, :component
    add_index :optimia_technical_incidents, :status
    add_index :optimia_technical_incidents, :started_at

    create_table :optimia_technical_timeline_events do |t|
      t.references :optimia_channel_connection, foreign_key: true
      t.references :account, foreign_key: true
      t.string :component, null: false
      t.string :event_type, null: false
      t.string :summary, null: false
      t.jsonb :metadata, default: {}
      t.datetime :occurred_at, null: false
      t.timestamps
    end
    add_index :optimia_technical_timeline_events, :component
    add_index :optimia_technical_timeline_events, :event_type
    add_index :optimia_technical_timeline_events, :occurred_at

    create_table :optimia_technical_metric_snapshots do |t|
      t.datetime :recorded_at, null: false
      t.jsonb :metrics, default: {}
      t.timestamps
    end
    add_index :optimia_technical_metric_snapshots, :recorded_at

    create_table :optimia_deployment_records do |t|
      t.string :version, null: false
      t.string :commit_sha
      t.string :image_digest
      t.string :image_tag
      t.string :environment, default: 'staging'
      t.string :status, default: 'published'
      t.string :server_name
      t.datetime :deployed_at
      t.jsonb :metadata, default: {}
      t.timestamps
    end
    add_index :optimia_deployment_records, :deployed_at
    add_index :optimia_deployment_records, :version
  end
end
