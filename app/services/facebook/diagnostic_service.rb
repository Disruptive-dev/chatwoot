# frozen_string_literal: true

class Facebook::DiagnosticService
  include Facebook::GraphApiSupport

  pattr_initialize [:inbox!, :psid: nil]

  def perform
    channel = inbox.channel
    raise ArgumentError, 'Inbox channel is not Channel::FacebookPage' unless channel.is_a?(Channel::FacebookPage)

    result = base_result(channel)
    result.merge!(page_lookup_result(channel))
    result.merge!(profile_lookup_result(channel)) if sample_psid.present?
    result.merge!(token_debug_result(channel))
    result
  end

  private

  def base_result(channel)
    {
      inbox_id: inbox.id,
      account_id: inbox.account_id,
      page_id: channel.page_id,
      channel_id: channel.id,
      channel_present: true,
      page_access_token_present: channel.page_access_token.present?,
      page_access_token_fingerprint: token_fingerprint(channel.page_access_token),
      graph_api_version: api_version,
      sample_psid: sample_psid,
      recipient_page_id_matches_channel: true
    }
  end

  def page_lookup_result(channel)
    api = koala_api(channel.page_access_token)
    page_data = api.get_object(channel.page_id, fields: 'id,name')
    {
      page_lookup: 'succeeded',
      page_name: page_data['name'],
      page_lookup_page_id: page_data['id']
    }
  rescue StandardError => e
    {
      page_lookup: 'failed',
      page_lookup_error: sanitized_error(e)
    }
  end

  def profile_lookup_result(channel)
    api = koala_api(channel.page_access_token)
    profile_data = api.get_object(sample_psid, fields: Facebook::ProfileFetcher::PROFILE_FIELDS)
    {
      profile_lookup: 'succeeded',
      profile_has_name: profile_data['name'].present? || profile_data['first_name'].present?
    }
  rescue StandardError => e
    {
      profile_lookup: 'failed',
      profile_lookup_error: sanitized_error(e)
    }
  end

  def token_debug_result(channel)
    app_id = GlobalConfigService.load('FB_APP_ID', '')
    app_secret = GlobalConfigService.load('FB_APP_SECRET', '')
    return { token_debug: 'skipped', token_debug_reason: 'fb_app_credentials_missing' } if app_id.blank? || app_secret.blank?

    api = koala_api("#{app_id}|#{app_secret}")
    debug_data = api.get_object('debug_token', input_token: channel.page_access_token)
    data = debug_data['data'] || {}
    {
      token_debug: 'succeeded',
      token_is_valid: data['is_valid'],
      token_type: data['type'],
      token_scopes: data['scopes'],
      token_expires_at: data['expires_at']
    }
  rescue StandardError => e
    {
      token_debug: 'failed',
      token_debug_error: sanitized_error(e)
    }
  end

  def sample_psid
    @sample_psid ||= psid.presence || inbox.contact_inboxes.order(:id).last&.source_id
  end

  def sanitized_error(error)
    graph_error_metadata(error).merge(error_class: error.class.name)
  end
end
