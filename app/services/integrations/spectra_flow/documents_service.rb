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

  def health_check
    with_client(&:health_check)
  end

  private

  def with_client
    client = Integrations::SpectraFlow::Client.new(account: account)
    yield client
  rescue Integrations::SpectraFlow::Client::ConfigurationError => e
    Integrations::SpectraFlow::Client.log_configuration_failure(account: account, error: e)
    {
      error: e.message,
      error_code: e.error_code,
      status: e.http_status
    }
  end
end
