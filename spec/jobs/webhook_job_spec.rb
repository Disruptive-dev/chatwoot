require 'rails_helper'

RSpec.describe WebhookJob do
  include ActiveJob::TestHelper

  subject(:job) { described_class.perform_later(url, payload, webhook_type) }

  let(:url) { 'https://test.chatwoot.com' }
  let(:payload) { { name: 'test' } }
  let(:webhook_type) { :account_webhook }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(described_class)
      .with(url, payload, webhook_type)
      .on_queue('medium')
  end

  it 'executes perform with default webhook type' do
    expect(Webhooks::Trigger).to receive(:execute).with(url, payload, webhook_type)
    perform_enqueued_jobs { job }
  end

  context 'with custom webhook type' do
    let(:webhook_type) { :api_inbox_webhook }

    it 'executes perform with inbox webhook type' do
      expect(Webhooks::Trigger).to receive(:execute).with(url, payload, webhook_type)
      perform_enqueued_jobs { job }
    end

    context 'when url targets evolution chatwoot webhook' do
      let(:url) { 'https://evo.example.com/chatwoot/webhook/optimia-1-test' }

      it 'uses the optimia evolution delivery handler' do
        expect(Integrations::Optimia::ChannelManager::EvolutionWebhookDelivery).to receive(:execute).with(url, payload)
        expect(Webhooks::Trigger).not_to receive(:execute)
        perform_enqueued_jobs { job }
      end
    end
  end
end
