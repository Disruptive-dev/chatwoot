# frozen_string_literal: true

module Integrations
  module Optimia
    module ChannelManager
      class Feature
        FLAG_NAME = 'optimia_channel_manager'

        def self.enabled_for_account?(account)
          return false if account.blank?
          return false unless globally_enabled?

          account.feature_enabled?(FLAG_NAME)
        end

        def self.globally_enabled?
          value = ENV.fetch('OPTIMIA_CHANNEL_MANAGER_ENABLED', nil)
          return ActiveModel::Type::Boolean.new.cast(value) unless value.nil?

          db_value = GlobalConfig.get('OPTIMIA_CHANNEL_MANAGER_ENABLED')['OPTIMIA_CHANNEL_MANAGER_ENABLED']
          return ActiveModel::Type::Boolean.new.cast(db_value) unless db_value.nil?

          true
        end
      end
    end
  end
end
