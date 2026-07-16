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
      render json: { error: public_error_message(result) }, status: http_status_for(result[:status])
    else
      render json: result[:data], status: :ok
    end
  end

  def public_error_message(result)
    status = result[:status].to_i
    detail = result[:error].to_s

    case status
    when 401
      'No se pudo conectar con Spectra.'
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
    when 502, 503, 504
      'No se pudo conectar con Spectra.'
    else
      'No se pudo conectar con Spectra.'
    end
  end

  def http_status_for(code)
    code = code.to_i
    return :bad_gateway unless code.between?(400, 599)

    code
  end
end
