# frozen_string_literal: true

class Api::V1::Accounts::Optimia::Whatsapp::ConnectionsController < Api::V1::Accounts::BaseController
  before_action :ensure_feature_enabled!
  before_action :fetch_connection, except: [:index, :create]

  def index
    authorize(OptimiaChannelConnection)
    result = service.list_connections
    render json: result
  end

  def create
    authorize(OptimiaChannelConnection)
    result = service.create_connection(
      display_name: connection_params[:display_name],
      provider: connection_params[:provider].presence || 'evolution',
      channel_type: connection_params[:channel_type].presence || 'whatsapp'
    )
    render json: result, status: :created
  rescue Optimia::ChannelManager::ConnectionCenterService::ServiceError => e
    render_service_error(e)
  end

  def show
    authorize(@connection)
    result = service.show_connection(@connection)
    render json: result
  end

  def status
    authorize(@connection)
    result = service.refresh_status!(@connection)
    render json: result
  rescue Optimia::ChannelManager::ConnectionCenterService::ServiceError => e
    render_service_error(e)
  end

  def qr
    authorize(@connection)
    result = service.generate_qr!(@connection)
    render json: result
  rescue Optimia::ChannelManager::ConnectionCenterService::ServiceError => e
    render_service_error(e)
  end

  def reconnect
    authorize(@connection)
    result = service.reconnect!(@connection)
    render json: result
  rescue Optimia::ChannelManager::ConnectionCenterService::ServiceError => e
    render_service_error(e)
  end

  def disconnect
    authorize(@connection)
    result = service.disconnect!(@connection)
    render json: result
  rescue Optimia::ChannelManager::ConnectionCenterService::ServiceError => e
    render_service_error(e)
  end

  def pairing_code
    authorize(@connection)
    result = service.request_pairing_code!(@connection, phone_number: pairing_code_params[:phone_number])
    render json: result
  rescue Optimia::ChannelManager::ConnectionCenterService::ServiceError => e
    render_service_error(e)
  end

  private

  def ensure_feature_enabled!
    return if Integrations::Optimia::ChannelManager::Feature.enabled_for_account?(Current.account)

    render json: {
      error: I18n.t('optimia.whatsapp_connections.errors.feature_disabled'),
      error_code: 'feature_disabled'
    }, status: :forbidden
  end

  def fetch_connection
    @connection = policy_scope(OptimiaChannelConnection).find(params[:id])
  end

  def service
    @service ||= Optimia::ChannelManager::ConnectionCenterService.new(
      account: Current.account,
      performed_by: Current.user
    )
  end

  def connection_params
    params.permit(:display_name, :provider, :channel_type)
  end

  def pairing_code_params
    params.permit(:phone_number)
  end

  def render_service_error(error)
    render json: {
      error: error.message,
      error_code: error.error_code
    }, status: error.http_status
  end
end
