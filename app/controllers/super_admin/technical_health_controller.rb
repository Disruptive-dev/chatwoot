# frozen_string_literal: true

class SuperAdmin::TechnicalHealthController < SuperAdmin::ApplicationController
  def show
    @dashboard = Optimia::TechnicalHealth::NocDashboardService.build
    @connections = Optimia::TechnicalHealth::ConnectionMonitorService.list
    @deployment = Optimia::TechnicalHealth::DeploymentCenterService.current
    @alerts = OptimiaTechnicalAlert.recent.limit(50)
    @incidents = OptimiaTechnicalIncident.recent.limit(20)
  end

  def refresh
    Optimia::TechnicalHealth::Orchestrator.run!
    redirect_to super_admin_technical_health_path, notice: I18n.t('optimia.technical_health.notices.checks_refreshed')
  end

  def diagnose
    connection = params[:connection_id].present? ? OptimiaChannelConnection.find(params[:connection_id]) : nil
    @diagnostic = Optimia::TechnicalHealth::DiagnosticCenterService.new(connection: connection).perform!
    @diagnostic = Integrations::Optimia::TechnicalHealth::Sanitizer.sanitize(@diagnostic)

    respond_to do |format|
      format.json { render json: @diagnostic }
      format.html
    end
  end

  def connection_timeline
    connection = OptimiaChannelConnection.find(params[:connection_id])
    @timeline = Optimia::TechnicalHealth::TimelineBuilderService.new(connection: connection).build
    @timeline = Integrations::Optimia::TechnicalHealth::Sanitizer.sanitize(@timeline)
    @connection = connection

    respond_to do |format|
      format.json { render json: @timeline }
      format.html
    end
  end

  def acknowledge_alert
    alert = OptimiaTechnicalAlert.find(params[:alert_id])
    alert.update!(status: 'acknowledged', acknowledged_at: Time.current)
    redirect_to super_admin_technical_health_path, notice: I18n.t('optimia.technical_health.notices.alert_acknowledged')
  end

  def resolve_alert
    alert = OptimiaTechnicalAlert.find(params[:alert_id])
    alert.update!(status: 'resolved', resolved_at: Time.current)
    redirect_to super_admin_technical_health_path, notice: I18n.t('optimia.technical_health.notices.alert_resolved')
  end

  def acknowledge_incident
    incident = OptimiaTechnicalIncident.find(params[:incident_id])
    Optimia::TechnicalHealth::IncidentService.new.acknowledge!(incident: incident, responsible: current_super_admin&.email)
    redirect_to super_admin_technical_health_path, notice: I18n.t('optimia.technical_health.notices.incident_acknowledged')
  end

  def resolve_incident
    incident = OptimiaTechnicalIncident.find(params[:incident_id])
    Optimia::TechnicalHealth::IncidentService.new.resolve!(
      incident: incident,
      root_cause: params[:root_cause],
      action_taken: params[:action_taken],
      responsible: current_super_admin&.email
    )
    redirect_to super_admin_technical_health_path, notice: I18n.t('optimia.technical_health.notices.incident_resolved')
  end
end
