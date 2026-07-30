# frozen_string_literal: true

module Facebook::GraphApiSupport
  module_function

  def api_version
    GlobalConfigService.load('FACEBOOK_API_VERSION', 'v18.0')
  end

  def koala_api(access_token)
    Koala.config.api_version = api_version
    Koala::Facebook::API.new(access_token)
  end

  def token_fingerprint(access_token)
    return nil if access_token.blank?

    Digest::SHA256.hexdigest(access_token.to_s)[0, 12]
  end

  def log_event(event, payload)
    Rails.logger.info(payload.merge(event: event).compact.to_json)
  end

  def graph_error_metadata(error)
    metadata = {
      error_type: error.try(:fb_error_type),
      error_code: error.try(:fb_error_code),
      error_subcode: error.try(:fb_error_subcode),
      fbtrace_id: error.try(:fbtrace_id)
    }

    error_body = error_body_for(error)
    if error_body.is_a?(Hash)
      metadata[:error_subcode] ||= error_body['error_subcode'] || error_body['subcode']
      metadata[:fbtrace_id] ||= error_body['fbtrace_id']
      metadata[:error_type] ||= error_body['type']
      metadata[:error_code] ||= error_body['code']
    end

    metadata.compact
  end

  def error_body_for(error)
    return error if error.is_a?(Hash)

    return error.message if error.respond_to?(:message) && error.message.is_a?(Hash)

    embedded_error_hash(error)
  end

  def embedded_error_hash(error)
    return unless error.respond_to?(:instance_variables)

    error.instance_variables.each do |ivar|
      value = error.instance_variable_get(ivar)
      return value if value.is_a?(Hash) && value.key?('code')
    end

    nil
  end

  def mask_psid(psid)
    psid_str = psid.to_s
    return nil if psid_str.blank?
    return '***' if psid_str.length <= 4

    "#{psid_str[0, 2]}***#{psid_str[-2, 2]}"
  end
end
