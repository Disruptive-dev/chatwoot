# Auditoría técnica — Technical Health Center v0.2.0

Auditoría de componentes monitoreados y su integración con el centro de salud. Fecha de referencia: 2026-07-24.

## Rails / Puma

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Versión | ✅ | Chatwoot 4.10.1 / OptimiA 0.2.0 |
| Health check | ✅ | `RailsChecker` detecta migraciones pendientes y uptime |
| Super Admin UI | ✅ | Dashboard en `/super_admin/technical_health` |
| API interna | ✅ | `/internal/health` con autenticación por token |
| Riesgo | 🟡 | Sin endpoint `/health` público estándar (solo interno) |

**Recomendación:** Configurar `OPTIMIA_INTERNAL_HEALTH_TOKEN` en prod/staging para monitoreo externo sin sesión.

## Sidekiq

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Worker prod | ✅ verificado Sprint 1 | Servicio `chatwoot-sidekiq` operativo |
| Checker | ✅ | Procesos, latencia, enqueued/failed |
| UI nativa | ✅ | `/monitoring/sidekiq` (super_admin) |
| Alertas | ✅ | `sidekiq_stopped`, `excessive_retries`, `pending_messages` |
| Riesgo | 🟡 | Latencia > 30s → `degraded`; sin auto-remediación |

## Redis

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Servicio prod | ✅ | `chatwoot-redis` |
| Checker | ✅ | Ping + latencia + `connected_clients` |
| Umbral | ✅ | > 200 ms → `degraded`; sin conexión → `critical` |
| Alerta | ✅ | `redis_down` (critical) |

## PostgreSQL

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Servicio prod | ✅ | `chatwoot-db` |
| Checker | ✅ | `SELECT 1`, latencia, pool size |
| Umbral | ✅ | > 500 ms → `degraded` |
| Métricas | ✅ | Tamaño BD en `StorageChecker` |
| Riesgo | 🟡 | Sin monitoreo de réplicas o conexiones máximas |

## Evolution API

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Integración | ✅ Sprint 2 | `Integrations::Evolution::Client` |
| Checker | ✅ | Health check con latencia |
| Sin config | ⚪ | Estado `unknown` si faltan ENV |
| Alerta | ✅ | `evolution_down` (critical) |
| Riesgo | 🟡 | Dependencia externa; sin circuit breaker |

## WhatsApp / Channel Manager

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Modelo | ✅ | `OptimiaChannelConnection` con máquina de estados |
| Checker | ✅ | Conteo por estado (operational, QR, error) |
| Monitor job | ✅ | Cada 2 min (`MonitorConnectionsJob`) |
| Diagnóstico | ✅ | Por conexión vía `DiagnosticCenterService` |
| Alertas | ✅ | `qr_expired`, `consecutive_errors` |
| Riesgo | 🟡 | Requiere staging QA con Evolution real |

## Webhooks

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Checker | ✅ | Valida `Channel::Api` + `webhook_url` por conexión |
| Alerta | ✅ | `webhook_broken` (critical) |
| Sanitización | ✅ | `webhook_url` excluido de payloads JSON |
| Riesgo | 🟡 | No verifica reachability HTTP del endpoint |

## Docker / Swarm

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Checker | ✅ | Lee `OPTIMIA_SWARM_SERVICE`, `OPTIMIA_NODE_ROLE` |
| Sin ENV | ⚪ | Estado `unknown` |
| Limitación | 🟡 | No consulta API Docker/Swarm; solo metadatos ENV |
| EasyPanel | 🟡 | Sin integración directa con API EasyPanel |

**Recomendación:** Inyectar `OPTIMIA_SWARM_SERVICE` y `OPTIMIA_NODE_ROLE` en compose/EasyPanel.

## Jobs / Scheduler

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Jobs checker | ✅ | Backlog, retry, dead, colas individuales |
| Scheduler checker | ✅ | Sidekiq-Cron jobs habilitados |
| Collect job | ✅ | `*/5 * * * *` en `config/schedule.yml` |
| Umbrales | ✅ | Backlog > 5000 → alerta; retry > 100 → alerta |

## Deploy

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Checker | ✅ | Versión, tag, digest, migraciones pendientes |
| Registro | ✅ | `OptimiaDeploymentRecord` + `DeploymentCenterService` |
| Imagen prod actual | ℹ️ | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Imagen staging propuesta | ℹ️ | `staging-cw-4.10.1-optimia-0.2.0` |
| Alerta | ✅ | `deploy_incomplete` si hay migraciones pendientes |

## Storage

| Aspecto | Estado | Detalle |
|---------|--------|---------|
| Checker | ✅ | `df` disco raíz + tamaño BD PostgreSQL |
| Umbrales | ✅ | ≥ 75% degraded, ≥ 90% critical |
| Limitación | 🟡 | Solo disco `/`; no monitorea S3/R2 externo |
| Alerta | ✅ | `storage_full` (critical) |

## Seguridad

| Control | Estado |
|---------|--------|
| Sanitización de payloads | ✅ Claves sensibles filtradas |
| API interna con token | ✅ `secure_compare` |
| Super Admin auth | ✅ Devise super_admin |
| Sin secretos en docs | ✅ |
| CSRF en API interna | ✅ `null_session` |

## Cobertura de tests

| Área | Specs |
|------|-------|
| Orchestrator | ✅ |
| Alert detector | ✅ |
| Diagnostic center | ✅ |
| Health controller (internal) | ✅ |
| Super Admin controller | ✅ |
| Collect job | ✅ |
| Checkers individuales | Parcial (vía orchestrator) |

## Hallazgos globales

1. **Fortaleza:** Monitoreo unificado sin SSH, integrado con Channel Manager.
2. **Gap:** Docker/Swarm checker depende de ENV, no de API real.
3. **Gap:** Staging no desplegado; validación end-to-end pendiente.
4. **Gap:** Producción en imagen `optimia.6`; v0.2.0 no desplegada (por diseño).
5. **Gap:** Webhooks verifican configuración, no conectividad HTTP.
