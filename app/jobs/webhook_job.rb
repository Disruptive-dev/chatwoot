class WebhookJob < ApplicationJob
  queue_as :medium
  #  There are 3 types of webhooks, account, inbox and agent_bot
  def perform(url, payload, webhook_type = :account_webhook)
    if webhook_type == :api_inbox_webhook &&
       Integrations::Optimia::ChannelManager::EvolutionWebhookDelivery.evolution_webhook?(url)
      Integrations::Optimia::ChannelManager::EvolutionWebhookDelivery.execute(url, payload)
      return
    end

    Webhooks::Trigger.execute(url, payload, webhook_type)
  end
end
