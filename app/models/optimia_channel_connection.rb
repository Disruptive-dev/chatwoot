# frozen_string_literal: true

class OptimiaChannelConnection < ApplicationRecord
  include OptimiaChannelConnectionStateMachine

  PROVIDERS = %w[evolution].freeze
  CHANNEL_TYPES = %w[whatsapp].freeze

  belongs_to :account
  belongs_to :inbox, optional: true
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true

  has_many :optimia_channel_connection_audits, dependent: :destroy_async

  encrypts :encrypted_credentials if Chatwoot.encryption_configured?

  validates :provider, inclusion: { in: PROVIDERS }
  validates :channel_type, inclusion: { in: CHANNEL_TYPES }
  validates :display_name, presence: true
  validates :account_id, presence: true
  validates :external_instance_id, uniqueness: { scope: :provider }, allow_nil: true
  validates :phone_number, uniqueness: { scope: :account_id }, allow_nil: true

  scope :for_account, ->(account_id) { where(account_id: account_id) }
  scope :whatsapp, -> { where(channel_type: 'whatsapp') }

  def credentials
    return {} if encrypted_credentials.blank?

    JSON.parse(encrypted_credentials)
  rescue JSON::ParserError
    {}
  end

  def credentials=(value)
    self.encrypted_credentials = value.present? ? value.to_json : nil
  end

  def merge_credentials!(value)
    self.credentials = credentials.merge(value.stringify_keys)
    save!
  end

  def merge_metadata!(value)
    self.connection_metadata = (connection_metadata || {}).merge(value.stringify_keys)
    save!
  end

  def generate_external_instance_id!
    generated = "optimia-#{account_id}-#{SecureRandom.hex(8)}"
    update!(external_instance_id: generated)
    generated
  end

  def mark_error!(code:, message:)
    update!(
      last_error_code: code,
      last_error_message: message
    )
    transition_to!('error') if can_transition_to?('error')
  end

  def clear_error!
    update!(last_error_code: nil, last_error_message: nil)
  end

  def public_attributes
    {
      id: id,
      display_name: display_name,
      phone_number: phone_number,
      state: state,
      channel_type: channel_type,
      provider: provider,
      inbox_id: inbox_id,
      qr_expires_at: qr_expires_at,
      last_connected_at: last_connected_at,
      last_disconnected_at: last_disconnected_at,
      last_error_code: public_error_code,
      status_message: public_status_message,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  def public_error_code
    return nil if last_error_code.blank?

    last_error_code
  end

  def public_status_message
    return I18n.t('optimia.whatsapp_connections.status.ready') if state == 'ready'
    return last_error_message if state == 'error' && last_error_message.present?

    I18n.t("optimia.whatsapp_connections.status.#{state}", default: state.humanize)
  end

  def qr_countdown_seconds
    return 0 if qr_expires_at.blank?

    [qr_expires_at.to_i - Time.current.to_i, 0].max
  end
end
