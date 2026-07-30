# frozen_string_literal: true

module Facebook::ContactNameResolver
  DEFAULT_FACEBOOK_CONTACT_NAME = 'Facebook User'
  LEGACY_FALLBACK_CONTACT_NAME = 'John Doe'

  module_function

  def resolve(result)
    payload = result.to_h.stringify_keys
    first_name = normalize_component(payload['first_name'])
    last_name = normalize_component(payload['last_name'])
    name = normalize_component(payload['name'])

    full_name = [first_name, last_name].compact_blank.join(' ')
    full_name = name if full_name.blank?
    full_name.presence || DEFAULT_FACEBOOK_CONTACT_NAME
  end

  def legacy_fallback?(name)
    normalize_component(name) == LEGACY_FALLBACK_CONTACT_NAME
  end

  def refreshable_fallback?(name)
    normalized = normalize_component(name)
    normalized.in?([LEGACY_FALLBACK_CONTACT_NAME, DEFAULT_FACEBOOK_CONTACT_NAME])
  end

  def normalize_component(value)
    value.to_s.strip.presence
  end
end
