# frozen_string_literal: true

class OptimiaChannelConnectionPolicy < ApplicationPolicy
  def index?
    feature_enabled? && administrator?
  end

  def show?
    feature_enabled? && administrator? && account_record?
  end

  def create?
    feature_enabled? && administrator?
  end

  def update?
    feature_enabled? && administrator? && account_record?
  end

  def qr?
    update?
  end

  def status?
    show?
  end

  def reconnect?
    update?
  end

  def disconnect?
    update?
  end

  def pairing_code?
    update?
  end

  def diagnose?
    show?
  end

  def sync_webhook?
    update?
  end

  class Scope < Scope
    def resolve
      return scope.none unless Integrations::Optimia::ChannelManager::Feature.enabled_for_account?(account)

      scope.where(account_id: account.id)
    end
  end

  private

  def feature_enabled?
    Integrations::Optimia::ChannelManager::Feature.enabled_for_account?(account)
  end

  def administrator?
    account_user&.administrator?
  end

  def account_record?
    record.account_id == account.id
  end
end
