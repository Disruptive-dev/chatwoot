# frozen_string_literal: true

FactoryBot.define do
  factory :optimia_channel_connection do
    account
    display_name { 'WhatsApp Ventas' }
    provider { 'evolution' }
    channel_type { 'whatsapp' }
    state { 'draft' }
    connection_metadata { {} }

    after(:build) do |connection|
      user = create(:user, account: connection.account, role: :administrator)
      connection.created_by ||= user
      connection.updated_by ||= user
    end
  end
end
