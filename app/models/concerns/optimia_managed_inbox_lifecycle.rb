# frozen_string_literal: true

module OptimiaManagedInboxLifecycle
  extend ActiveSupport::Concern

  included do
    has_one :optimia_channel_connection, dependent: :nullify

    before_destroy :optimia_prepare_managed_inbox_destruction, prepend: true
  end

  def optimia_managed?
    optimia_channel_connection.present?
  end

  private

  def optimia_prepare_managed_inbox_destruction
    connection = OptimiaChannelConnection.find_by(inbox_id: id)
    return if connection.blank?

    Optimia::ChannelManager::InboxDeletionCoordinator.prepare_for_inbox_destroy!(
      inbox: self,
      connection: connection,
      performed_by: Thread.current[:optimia_inbox_destroy_performed_by]
    )
  end
end
