# frozen_string_literal: true

Rails.application.config.to_prepare do
  require Rails.root.join('lib/integrations/optimia/channel_manager/providers/evolution_adapter')

  Integrations::Optimia::ChannelManager::ProviderRegistry.register(
    'evolution',
    Integrations::Optimia::ChannelManager::Providers::EvolutionAdapter
  )
end
