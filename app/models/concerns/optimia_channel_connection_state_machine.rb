# frozen_string_literal: true

module OptimiaChannelConnectionStateMachine
  extend ActiveSupport::Concern

  STATES = %w[
    draft
    creating
    created
    waiting_qr
    waiting_scan
    pairing
    connected
    syncing
    ready
    reconnecting
    qr_required
    disconnected
    degraded
    failed
    error
    disabled
  ].freeze

  TERMINAL_STATES = %w[ready disabled].freeze

  TRANSITIONS = {
    'draft' => %w[creating disabled],
    'creating' => %w[created error failed draft],
    'created' => %w[waiting_qr error failed disabled],
    'waiting_qr' => %w[waiting_scan pairing error failed disabled],
    'waiting_scan' => %w[pairing connected error failed disconnected disabled],
    'pairing' => %w[connected waiting_scan error failed disconnected disabled],
    'connected' => %w[syncing error failed disconnected disabled],
    'syncing' => %w[ready error failed disconnected disabled],
    'ready' => %w[disconnected reconnecting degraded qr_required failed error disabled],
    'reconnecting' => %w[ready waiting_qr waiting_scan connected degraded qr_required failed error disconnected disabled],
    'qr_required' => %w[waiting_qr reconnecting disconnected failed disabled],
    'disconnected' => %w[reconnecting draft qr_required failed disabled],
    'degraded' => %w[ready reconnecting qr_required failed disconnected disabled],
    'failed' => %w[reconnecting qr_required draft disabled error],
    'error' => %w[draft reconnecting failed disabled qr_required],
    'disabled' => %w[draft]
  }.freeze

  included do
    validates :state, inclusion: { in: STATES }
    before_validation :ensure_initial_state, on: :create
  end

  def transition_to!(new_state, metadata: {})
    new_state = new_state.to_s
    raise ArgumentError, "Invalid state: #{new_state}" unless STATES.include?(new_state)
    raise ArgumentError, "Invalid transition from #{state} to #{new_state}" unless can_transition_to?(new_state)

    previous_state = state
    updates = { state: new_state }
    updates[:last_state_change_at] = Time.current if has_attribute?(:last_state_change_at)
    update!(updates)
    yield(previous_state, new_state) if block_given?
    [previous_state, new_state]
  end

  def can_transition_to?(new_state)
    TRANSITIONS.fetch(state, []).include?(new_state.to_s)
  end

  def terminal?
    TERMINAL_STATES.include?(state)
  end

  private

  def ensure_initial_state
    self.state = 'draft' if state.blank?
  end
end
