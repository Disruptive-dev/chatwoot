# frozen_string_literal: true

class Internal::HealthController < ApplicationController
  include Internal::HealthAuthentication

  protect_from_forgery with: :null_session

  def index
    render json: sanitized_payload(Optimia::TechnicalHealth::NocDashboardService.build)
  end

  def redis
    render json: sanitized_payload(component_payload('redis'))
  end

  def postgres
    render json: sanitized_payload(component_payload('postgres'))
  end

  def evolution
    render json: sanitized_payload(component_payload('evolution'))
  end

  def webhooks
    render json: sanitized_payload(component_payload('webhooks'))
  end

  def sidekiq
    render json: sanitized_payload(component_payload('sidekiq'))
  end

  def storage
    render json: sanitized_payload(component_payload('storage'))
  end

  private

  def component_payload(component)
    check = OptimiaTechnicalHealthCheck.latest_for(component)
    return { component: component, status: 'unknown' } unless check

    check.as_json(only: %i[component status latency_ms version uptime_seconds error_count metadata checked_at])
  end

  def sanitized_payload(payload)
    Integrations::Optimia::TechnicalHealth::Sanitizer.sanitize(payload)
  end
end
