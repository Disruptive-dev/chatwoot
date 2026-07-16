# frozen_string_literal: true

class Api::V1::Accounts::Spectra::DocumentsController < Api::V1::Accounts::BaseController
  before_action :ensure_account_member!

  def index
    result = documents_service.list_sendable(filter_params)
    render_spectra_result(result)
  end

  def download_token
    result = documents_service.create_download_token(params[:id])
    render_spectra_result(result)
  end

  def download
    result = documents_service.download(params[:id], params[:token].to_s)
    return render_spectra_result(result) if result[:error].present?

    payload = result[:data]
    filename = Integrations::SpectraFlow::Client.sanitize_filename(payload[:filename])
    encoded_filename = ERB::Util.url_encode(filename)

    send_data(
      payload[:body],
      type: payload[:content_type],
      disposition: "attachment; filename=\"#{filename}\"; filename*=UTF-8''#{encoded_filename}"
    )
  end

  private

  def ensure_account_member!
    raise Pundit::NotAuthorizedError unless Current.account_user
  end

  def documents_service
    Integrations::SpectraFlow::DocumentsService.new(account: Current.account)
  end

  def filter_params
    {
      q: params[:q].to_s.strip,
      category: params[:category].to_s.strip,
      tag: params[:tag].to_s.strip,
      limit: [[params[:limit].presence&.to_i || 100, 1].max, 200].min
    }
  end

  def render_spectra_result(result)
    if result[:error].present?
      payload = {
        error: public_error_message(result),
        error_code: result[:error_code] || infer_error_code(result)
      }
      log_public_error(result, payload[:error_code])
      render json: payload, status: http_status_for(result[:status])
    else
      render json: result[:data], status: :ok
    end
  end

  def infer_error_code(result)
    Integrations::SpectraFlow::Errors.error_code_for_status(result[:status])
  end

  def log_public_error(result, error_code)
    Rails.logger.warn(
      {
        event: 'spectra_documents_proxy_error',
        account_id: Current.account.id,
        error_code: error_code,
        upstream_status: result[:status],
        internal_message: result[:error]
      }.to_json
    )
  end

  def public_error_message(result)
    case result[:error_code]
    when 'spectra_not_configured'
      return 'La conexión con Spectra todavía no está configurada.'
    when 'spectra_authentication_failed'
      return 'La credencial de Spectra no es válida o venció.'
    when 'spectra_timeout'
      return 'Spectra tardó demasiado en responder.'
    when 'spectra_forbidden'
      return 'No tenés permisos para consultar documentos.'
    when 'spectra_endpoint_not_found'
      return 'No se pudo conectar con Spectra.'
    end

    status = result[:status].to_i
    detail = result[:error].to_s

    case status
    when 401
      'La credencial de Spectra no es válida o venció.'
    when 403
      if detail.match?(/token|expir/i)
        'El acceso temporal al documento expiró. Intentá nuevamente.'
      else
        'No tenés permisos para consultar documentos.'
      end
    when 404
      'El documento seleccionado ya no está disponible.'
    when 409
      'El documento no está disponible en este momento.'
    when 422
      if detail.match?(/size|large|tamaño/i)
        'El archivo supera el tamaño máximo permitido.'
      else
        'No se pudo preparar el documento seleccionado.'
      end
    when 504
      'Spectra tardó demasiado en responder.'
    when 502, 503
      if detail.match?(/not configured|token not configured|URL not configured/i)
        'La conexión con Spectra todavía no está configurada.'
      else
        'No se pudo conectar con Spectra.'
      end
    else
      'No se pudo conectar con Spectra.'
    end
  end

  def http_status_for(code)
    code = code.to_i
    return :service_unavailable if code == 503
    return :gateway_timeout if code == 504
    return :bad_gateway unless code.between?(400, 599)

    code
  end
end
