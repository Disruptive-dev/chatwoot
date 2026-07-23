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
    disconnected
    reconnecting
    error
    disabled
  ].freeze

  TERMINAL_STATES = %w[ready disabled].freeze

  TRANSITIONS = {
    'draft' => %w[creating disabled],
    'creating' => %w[created error draft],
    'created' => %w[waiting_qr error disabled],
    'waiting_qr' => %w[waiting_scan pairing error disabled],
    'waiting_scan' => %w[pairing connected error disconnected disabled],
    'pairing' => %w[connected waiting_scan error disconnected disabled],
    'connected' => %w[syncing error disconnected disabled],
    'syncing' => %w[ready error disconnected disabled],
    'ready' => %w[disconnected reconnecting error disabled],
    'disconnected' => %w[reconnecting draft error disabled],
    'reconnecting' => %w[waiting_qr waiting_scan connected error disabled],
    'error' => %w[draft reconnecting disabled],
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
    update!(state: new_state)
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
