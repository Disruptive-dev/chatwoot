# frozen_string_literal: true

class CreateOptimiaFacebookCommentTables < ActiveRecord::Migration[7.1]
  def change
    create_table :optimia_facebook_comment_events do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :channel_facebook_page, null: false, foreign_key: { to_table: :channel_facebook_pages }, index: true
      t.string :idempotency_key, null: false
      t.string :correlation_id, null: false
      t.string :page_id, null: false
      t.string :post_id
      t.string :comment_id, null: false
      t.string :parent_id
      t.string :sender_id
      t.text :message_text
      t.string :event_type, null: false, default: 'comment'
      t.string :status, null: false, default: 'received'
      t.string :property_id
      t.string :intent
      t.string :response_mode
      t.string :response_comment_id
      t.string :decision
      t.jsonb :metadata, null: false, default: {}
      t.text :error_message
      t.datetime :processed_at
      t.references :conversation, foreign_key: true, index: true

      t.timestamps
    end

    add_index :optimia_facebook_comment_events, :idempotency_key, unique: true
    add_index :optimia_facebook_comment_events, :comment_id
    add_index :optimia_facebook_comment_events, %i[account_id status]
    add_index :optimia_facebook_comment_events, :correlation_id

    create_table :optimia_facebook_comment_leads do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.references :optimia_facebook_comment_event, null: false,
                                                    foreign_key: true,
                                                    index: { name: 'index_optimia_fb_comment_leads_on_event_id' }
      t.string :idempotency_key, null: false
      t.string :channel, null: false, default: 'facebook'
      t.string :source, null: false, default: 'facebook_comment'
      t.string :page_id, null: false
      t.string :post_id
      t.string :comment_id, null: false
      t.string :property_id
      t.string :intent
      t.jsonb :contact_identifiers, null: false, default: {}
      t.string :source_message_id
      t.float :confidence
      t.datetime :captured_at, null: false
      t.references :conversation, foreign_key: true, index: true

      t.timestamps
    end

    add_index :optimia_facebook_comment_leads, :idempotency_key, unique: true
    add_index :optimia_facebook_comment_leads, %i[account_id comment_id]

    create_table :optimia_facebook_post_properties do |t|
      t.references :account, null: false, foreign_key: true, index: true
      t.string :page_id, null: false
      t.string :post_id, null: false
      t.string :property_id, null: false
      t.string :source, null: false, default: 'manual'
      t.float :confidence, null: false, default: 1.0
      t.jsonb :known_facts, null: false, default: {}

      t.timestamps
    end

    add_index :optimia_facebook_post_properties,
              %i[account_id post_id],
              unique: true,
              name: 'index_optimia_fb_post_properties_on_account_and_post'
  end
end
