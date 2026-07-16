# frozen_string_literal: true

class Integrations::SpectraFlow::DocumentsService
  pattr_initialize [:account!]

  def list_sendable(params)
    with_client { |client| client.list_sendable(**params) }
  end

  def create_download_token(item_id)
    with_client { |client| client.create_download_token(item_id) }
  end

  def download(item_id, token)
    with_client { |client| client.download(item_id, token) }
  end

  private

  def with_client
    yield Integrations::SpectraFlow::Client.new(account: account)
  rescue Integrations::SpectraFlow::Client::ConfigurationError => e
    { error: e.message, status: 503 }
  end
end
