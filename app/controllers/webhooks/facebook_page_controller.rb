# frozen_string_literal: true

class Webhooks::FacebookPageController < ActionController::API
  include MetaTokenVerifyConcern
  include MetaWebhookSignatureVerification

  def events
    verify_meta_webhook_signature!
    return if performed?

    unless params['object'].to_s.casecmp('page').zero?
      Rails.logger.warn({ event: 'facebook_page_webhook_unsupported_object', object: params['object'] }.to_json)
      head :unprocessable_entity
      return
    end

    Webhooks::FacebookPageEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end

  private

  def valid_token?(token)
    token == GlobalConfigService.load('FB_VERIFY_TOKEN', '')
  end
end
