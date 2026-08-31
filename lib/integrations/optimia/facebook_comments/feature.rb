# frozen_string_literal: true

module Integrations
  module Optimia
    module FacebookComments
      class Feature
        COMMENTS_KEY = 'optimia_facebook_comments_enabled'
        AI_REPLY_KEY = 'optimia_facebook_comment_ai_reply_enabled'
        PRIVATE_REPLY_KEY = 'optimia_facebook_comment_private_reply_enabled'

        def self.comments_enabled_for_account?(account)
          flag_enabled?(account, COMMENTS_KEY)
        end

        def self.ai_reply_enabled_for_account?(account)
          comments_enabled_for_account?(account) && flag_enabled?(account, AI_REPLY_KEY)
        end

        def self.private_reply_enabled_for_account?(account)
          comments_enabled_for_account?(account) && flag_enabled?(account, PRIVATE_REPLY_KEY)
        end

        def self.enable_for_account!(account)
          attrs = account.custom_attributes || {}
          account.update!(
            custom_attributes: attrs.merge(
              COMMENTS_KEY => true,
              AI_REPLY_KEY => true,
              PRIVATE_REPLY_KEY => true
            )
          )
        end

        def self.disable_for_account!(account)
          attrs = account.custom_attributes || {}
          account.update!(
            custom_attributes: attrs.merge(
              COMMENTS_KEY => false,
              AI_REPLY_KEY => false,
              PRIVATE_REPLY_KEY => false
            )
          )
        end

        def self.flag_enabled?(account, key)
          return false if account.blank?

          value = account.custom_attributes&.fetch(key, nil)
          ActiveModel::Type::Boolean.new.cast(value)
        end
      end
    end
  end
end
