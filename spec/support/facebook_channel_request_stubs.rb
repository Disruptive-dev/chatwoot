# frozen_string_literal: true

RSpec.configure do |config|
  config.before do |example|
    path = example.metadata[:file_path]
    next unless path&.match?(%r{spec/(services/facebook|builders/messages/facebook|tasks/optimia_facebook)})

    stub_request(:post, /graph\.facebook\.com/).to_return(status: 200, body: '{}')
    allow(Facebook::Messenger::Subscriptions).to receive(:subscribe).and_return(true)
    allow(Facebook::Messenger::Subscriptions).to receive(:unsubscribe).and_return(true)
    InstallationConfig.where(name: 'ENABLE_MESSENGER_CHANNEL_HUMAN_AGENT').delete_all
  end
end
