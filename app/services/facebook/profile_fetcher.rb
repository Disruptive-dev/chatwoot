# frozen_string_literal: true

class Facebook::ProfileFetcher
  include Facebook::GraphApiSupport

  PROFILE_FIELDS = 'first_name,last_name,name'
  FALLBACK_NAME = 'John Doe'
  KNOWN_NON_BLOCKING_SUBCODES = [2_018_218].freeze

  pattr_initialize [:channel!, :psid!, :account_id!, :inbox_id!, :outgoing_echo]

  def perform
    log_event('facebook_profile_lookup_started', base_log_payload)

    result = fetch_profile
    contact_attributes = build_contact_attributes(result)

    log_event('facebook_profile_lookup_succeeded', base_log_payload.merge(profile_resolved: result.present?))

    contact_attributes
  rescue Koala::Facebook::AuthenticationError => e
    log_profile_failure(e)
    channel.authorization_error!
    raise
  rescue Koala::Facebook::ClientError => e
    log_profile_failure(e)
    build_contact_attributes({})
  rescue StandardError => e
    log_profile_failure(e)
    ChatwootExceptionTracker.new(e, account: channel.account).capture_exception unless outgoing_echo
    build_contact_attributes({})
  end

  private

  def fetch_profile
    return {} if psid.blank?
    return {} unless page_token_present?

    koala_api(channel.page_access_token).get_object(psid, fields: PROFILE_FIELDS) || {}
  end

  def build_contact_attributes(result)
    {
      name: contact_name(result),
      account_id: account_id,
      avatar_url: result['profile_pic']
    }
  end

  def contact_name(result)
    full_name = [result['first_name'], result['last_name']].compact_blank.join(' ')
    full_name = result['name'] if full_name.blank?
    full_name.presence || FALLBACK_NAME
  end

  def page_token_present?
    channel.page_access_token.present?
  end

  def log_profile_failure(error)
    metadata = graph_error_metadata(error)
    log_event(
      'facebook_profile_lookup_failed',
      base_log_payload.merge(
        error_class: error.class.name,
        **metadata
      )
    )

    return if outgoing_echo
    return if known_non_blocking_profile_error?(metadata)

    ChatwootExceptionTracker.new(error, account: channel.account).capture_exception
  end

  def known_non_blocking_profile_error?(metadata)
    metadata[:error_subcode].to_i.in?(KNOWN_NON_BLOCKING_SUBCODES)
  end

  def base_log_payload
    {
      account_id: account_id,
      inbox_id: inbox_id,
      page_id: channel.page_id,
      graph_api_version: api_version
    }
  end
end
