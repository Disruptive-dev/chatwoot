# frozen_string_literal: true

Rails.application.config.to_prepare do
  require Rails.root.join('lib/integrations/optimia/technical_health/sanitizer')
  require Rails.root.join('lib/integrations/optimia/technical_health/component_catalog')
end

if Rails.env.production? && ENV['OPTIMIA_INTERNAL_HEALTH_TOKEN'].blank?
  Rails.logger.warn('[OptimiA] OPTIMIA_INTERNAL_HEALTH_TOKEN is not set; internal health API accepts Super Admin session only')
end
