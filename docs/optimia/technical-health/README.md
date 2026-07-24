# OptimiA Technical Health Center — v0.2.0

Centro de salud técnica integrado en Super Admin para monitoreo operativo de la plataforma OptimiA (Chatwoot + Evolution + WhatsApp).

## Resumen

El Technical Health Center consolida el estado de 12 componentes críticos, alertas automáticas, incidentes, métricas históricas y diagnóstico de conexiones WhatsApp. No requiere SSH: toda la operación se realiza desde la UI de Super Admin o la API interna autenticada.

| Campo | Valor |
|-------|-------|
| Versión OptimiA | 0.2.0 |
| Base Chatwoot | 4.10.1 |
| Rama de desarrollo | `cursor/technical-health-center-3da0` |
| Recolección automática | Cada 5 minutos (Sidekiq Cron) |

## Rutas de acceso

### Super Admin (sesión `super_admin`)

| Ruta | Método | Descripción |
|------|--------|-------------|
| `/super_admin/technical_health` | GET | Dashboard NOC principal |
| `/super_admin/technical_health/refresh` | POST | Ejecutar checks manualmente |
| `/super_admin/technical_health/diagnose` | GET | Diagnóstico de plataforma o conexión (`?connection_id=`) |
| `/super_admin/technical_health/connections/:id/timeline` | GET | Timeline de eventos de conexión |
| `/super_admin/technical_health/alerts/:id/acknowledge` | POST | Reconocer alerta |
| `/super_admin/technical_health/alerts/:id/resolve` | POST | Resolver alerta |
| `/super_admin/technical_health/incidents/:id/acknowledge` | POST | Reconocer incidente |
| `/super_admin/technical_health/incidents/:id/resolve` | POST | Resolver incidente |

Navegación: **Super Admin → Technical Health** (sidebar).

### API interna (token o sesión super_admin)

| Ruta | Método | Descripción |
|------|--------|-------------|
| `/internal/health` | GET | Dashboard completo (JSON sanitizado) |
| `/internal/health/redis` | GET | Estado Redis |
| `/internal/health/postgres` | GET | Estado PostgreSQL |
| `/internal/health/evolution` | GET | Estado Evolution API |
| `/internal/health/webhooks` | GET | Estado webhooks WhatsApp |
| `/internal/health/sidekiq` | GET | Estado Sidekiq |
| `/internal/health/storage` | GET | Estado almacenamiento |

Autenticación: header `Authorization: Bearer <OPTIMIA_INTERNAL_HEALTH_TOKEN>` o sesión activa de super_admin.

## Módulos

| Módulo | Servicio / clase | Función |
|--------|------------------|---------|
| **NOC Dashboard** | `NocDashboardService` | Vista consolidada de componentes, conexiones, mensajes y jobs |
| **Orchestrator** | `Orchestrator` | Ejecuta los 12 checkers y persiste resultados |
| **Alert Detector** | `AlertDetectorService` | 11 reglas de alerta automática → incidentes |
| **Diagnostic Center** | `DiagnosticCenterService` | Score 0–100 y recomendaciones por plataforma/conexión |
| **Connection Monitor** | `ConnectionMonitorService` | Listado de conexiones WhatsApp con health score |
| **Timeline Builder** | `TimelineBuilderService` | Eventos de auditoría y conexión por línea temporal |
| **Deployment Center** | `DeploymentCenterService` | Versión, imagen, commit y historial de deploys |
| **Incident Service** | `IncidentService` | Ciclo de vida de incidentes (open → acknowledged → resolved) |
| **Metrics Collector** | `MetricsCollectorService` | Snapshots periódicos de latencias y contadores |
| **Sanitizer** | `Integrations::Optimia::TechnicalHealth::Sanitizer` | Elimina datos sensibles de payloads JSON |

## Checkers (componentes monitoreados)

| Componente | Checker | Criterios principales |
|------------|---------|----------------------|
| `rails` | `RailsChecker` | Migraciones pendientes, uptime, versión |
| `sidekiq` | `SidekiqChecker` | Procesos activos, latencia cola default |
| `postgres` | `PostgresChecker` | Latencia `SELECT 1`, pool de conexiones |
| `redis` | `RedisChecker` | Ping, latencia, clientes conectados |
| `evolution` | `EvolutionChecker` | Health check API Evolution |
| `docker` | `DockerChecker` | Metadatos Swarm (`OPTIMIA_SWARM_SERVICE`) |
| `storage` | `StorageChecker` | Uso disco `/`, tamaño BD |
| `jobs` | `JobsChecker` | Backlog, retry, dead set, colas |
| `scheduler` | `SchedulerChecker` | Jobs Sidekiq-Cron habilitados |
| `webhooks` | `WebhooksChecker` | Webhook `Channel::Api` por conexión activa |
| `whatsapp` | `WhatsappChecker` | Estados de `OptimiaChannelConnection` |
| `deploy` | `DeployChecker` | Versión imagen, migraciones, commit SHA |

Estados posibles: `healthy`, `degraded`, `critical`, `unknown`.

## Modelos

| Modelo | Tabla | Propósito |
|--------|-------|-----------|
| `OptimiaTechnicalHealthCheck` | `optimia_technical_health_checks` | Resultado de cada check por componente |
| `OptimiaTechnicalAlert` | `optimia_technical_alerts` | Alertas automáticas (open/acknowledged/resolved) |
| `OptimiaTechnicalIncident` | `optimia_technical_incidents` | Incidentes operativos con RCA |
| `OptimiaTechnicalTimelineEvent` | `optimia_technical_timeline_events` | Eventos de timeline por conexión |
| `OptimiaTechnicalMetricSnapshot` | `optimia_technical_metric_snapshots` | Métricas agregadas históricas |
| `OptimiaDeploymentRecord` | `optimia_deployment_records` | Registro de versiones desplegadas |

## Jobs programados

| Job | Cron | Cola | Descripción |
|-----|------|------|-------------|
| `Optimia::TechnicalHealth::CollectHealthJob` | `*/5 * * * *` | `scheduled_jobs` | Ejecuta `Orchestrator.run!` |
| `Optimia::ChannelManager::MonitorConnectionsJob` | `*/2 * * * *` | `scheduled_jobs` | Monitoreo conexiones WhatsApp (Sprint 2) |

## Variables de entorno

### Technical Health Center

| Variable | Req | Sens | Descripción |
|----------|-----|------|-------------|
| `OPTIMIA_INTERNAL_HEALTH_TOKEN` | Rec | S | Token Bearer para API `/internal/health/*` |
| `OPTIMIA_DEPLOY_VERSION` | O | — | Versión desplegada (default: `Optimia::VERSION`) |
| `OPTIMIA_DEPLOY_COMMIT_SHA` | O | — | SHA del commit en runtime |
| `OPTIMIA_DEPLOY_IMAGE_DIGEST` | O | — | Digest de imagen Docker |
| `OPTIMIA_DEPLOY_IMAGE_TAG` | O | — | Tag de imagen (default: `staging-cw-4.10.1-optimia-0.2.0`) |
| `OPTIMIA_SWARM_SERVICE` | O | — | Nombre del servicio Swarm/EasyPanel |
| `OPTIMIA_NODE_ROLE` | O | — | Rol del nodo (`web`, `worker`, etc.) |

### Dependencias (Sprint 2 — Channel Manager)

| Variable | Req | Sens | Descripción |
|----------|-----|------|-------------|
| `EVOLUTION_API_URL` | R* | — | URL base Evolution API |
| `EVOLUTION_API_KEY` | R* | S | API key Evolution |
| `OPTIMIA_CHATWOOT_PUBLIC_URL` | Rec | — | URL pública para webhooks |
| `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN` | Rec | S | Token API Chatwoot ↔ Evolution |
| `OPTIMIA_CHANNEL_MANAGER_ENABLED` | O | — | Feature flag Channel Manager |

\* Requeridas si Evolution está configurado; sin ellas el checker reporta `unknown`.

## Documentación relacionada

- [Auditoría técnica](audit.md)
- [Matriz de riesgos](risk-matrix.md)
- [Runbooks operativos](runbooks.md)
- [Resumen ejecutivo](executive-summary.md)
- Channel Manager: `docs/optimia/architecture/channel-manager-rfc.md`
- Variables completas: `docs/optimia/inventory/environment-variables.md`
