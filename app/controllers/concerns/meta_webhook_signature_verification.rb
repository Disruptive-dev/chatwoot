# frozen_string_literal: true

module MetaWebhookSignatureVerification
    extend ActiveSupport::Concern

    private

    def verify_meta_webhook_signature!
      signature = request.headers['X-Hub-Signature-256'].to_s
      return head :unauthorized if signature.blank?

      app_secret = GlobalConfigService.load('FB_APP_SECRET', '')
      return head :unauthorized if app_secret.blank?

      expected = "sha256=#{OpenSSL::HMAC.hexdigest('SHA256', app_secret, request.raw_post)}"
      return if ActiveSupport::SecurityUtils.secure_compare(expected, signature)

      Rails.logger.warn({ event: 'meta_webhook_signature_invalid' }.to_json)
      head :unauthorized
    end
end
