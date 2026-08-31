# frozen_string_literal: true

FactoryBot.define do
  factory :optimia_facebook_comment_event do
    account
    channel_facebook_page factory: %i[channel_facebook_page]
    sequence(:idempotency_key) { |n| "fb_comment:test:#{n}:comment_add" }
    correlation_id { SecureRandom.uuid }
    page_id { channel_facebook_page.page_id }
    post_id { '123_456' }
    sequence(:comment_id) { |n| "comment_#{n}" }
    sender_id { 'user_123' }
    message_text { 'Precio?' }
    event_type { 'comment_add' }
    status { 'received' }
    metadata { {} }
  end

  factory :optimia_facebook_post_property do
    account
    page_id { 'page_123' }
    sequence(:post_id) { |n| "post_#{n}" }
    property_id { 'prop_001' }
    source { 'manual' }
    confidence { 1.0 }
    known_facts { { 'price' => 'USD 150.000', 'location' => 'Palermo' } }
  end
end
