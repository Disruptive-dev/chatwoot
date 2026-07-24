# frozen_string_literal: true

Rails.application.config.to_prepare do
  require Rails.root.join('lib/integrations/optimia/technical_health/sanitizer')
  require Rails.root.join('lib/integrations/optimia/technical_health/component_catalog')
end
