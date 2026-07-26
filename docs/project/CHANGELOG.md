# CHANGELOG — OptimiA

> Cambios relevantes del producto y del repositorio.  
> Versionado de producto según [ADR-003](../optimia/adr/ADR-003-versioning-strategy.md).

## [Unreleased]

### Added (Sprint v0.2.1 — CI/CD Platform Cleanup)

- Pipeline unificado: `optimia-ci.yml`, `optimia-build-staging.yml`, `optimia-build-production.yml`.
- Documentación CI/CD en `docs/optimia/cicd/` (constitution, spec, decisions, plan, tasks, runbooks).
- Scripts: `scripts/optimia/ci-status.sh`, `image-inspect.sh`, `release-metadata.sh`, `validate-cicd.sh`.
- Guards upstream en 11 workflows heredados de Chatwoot (Docker Hub, Heroku, CI duplicado).
- Workflows legacy `build-optimia-chatwoot*.yml` deprecados.
- Registry activo parametrizado: fallback `ghcr.io/pablo-paez-dev/chatwoot`.

### Changed

- Producción protegida: sin auto-build en push `develop`.
- Staging registry unificado con producción (mismo namespace parametrizado).

### Pendiente

- Publicar imagen staging v0.2.0 (autorización humana post-merge).
- Configurar environment `production` y variables GitHub.
- Migración registry a `ghcr.io/dsw-factory/optimia-chatwoot` (requiere GHCR_TOKEN).

---

## OptimiA 0.2.0 — 2026-07-24

### Added (Sprint 3 — Technical Health Center)

- NOC Dashboard con monitoreo de 12 componentes (Rails, Sidekiq, Redis, PostgreSQL, Evolution, Docker, Storage, Jobs, Scheduler, Webhooks, WhatsApp, Deploy).
- `Orchestrator` + checkers + `AlertDetectorService` (11 reglas de alerta).
- `DiagnosticCenterService` con score y recomendaciones por plataforma/conexión.
- `ConnectionMonitorService` + `TimelineBuilderService` integrados con Channel Manager.
- `DeploymentCenterService` + modelo `OptimiaDeploymentRecord`.
- API interna `/internal/health/*` con token `OPTIMIA_INTERNAL_HEALTH_TOKEN`.
- UI Super Admin `/super_admin/technical_health` (dashboard, refresh, diagnose, timeline, alertas, incidentes).
- Job `Optimia::TechnicalHealth::CollectHealthJob` (cron cada 5 min).
- Migración `20260724160000_create_optimia_technical_health_tables`.
- Documentación `docs/optimia/technical-health/`.
- Versión producto: `Optimia::VERSION = '0.2.0'`.

### Variables ENV nuevas

- `OPTIMIA_INTERNAL_HEALTH_TOKEN`, `OPTIMIA_DEPLOY_VERSION`, `OPTIMIA_DEPLOY_COMMIT_SHA`
- `OPTIMIA_DEPLOY_IMAGE_DIGEST`, `OPTIMIA_DEPLOY_IMAGE_TAG`
- `OPTIMIA_SWARM_SERVICE`, `OPTIMIA_NODE_ROLE`

### Deploy

- Ninguno (staging pendiente).

---

### Added (Sprint 2 — Channel Manager + WhatsApp Connection Center)

- Modelo `OptimiaChannelConnection` con máquina de estados y auditoría.
- Evolution API adapter + Provider Registry (`lib/integrations/evolution/`, `lib/integrations/optimia/channel_manager/`).
- API `optimia/whatsapp/connections` (QR, status, reconnect, disconnect).
- UI Configuración → WhatsApp con wizard, polling y multi-número.
- Provisioning idempotente de inbox Chatwoot (`Channel::Api`).
- Feature flag `optimia_channel_manager`, ADR-004, RFC, runbook staging.

### Added (Sprint 1 — preparación staging)

- `docs/optimia/environments/` — arquitectura staging aislado, imágenes, variables, web/worker, controles.
- `docs/optimia/operations/easypanel-staging-setup-guide.md`.
- `.github/workflows/build-optimia-chatwoot-staging.yml` — build manual, tags `staging-*`.

### Pendiente

- Publicar imagen staging (workflow manual).
- Crear proyecto staging en EasyPanel (acción humana).
- Aprobación ADRs por propietario.
- Docker v2 (post-staging operativo).

---

## OptimiA 0.1.2 — 2026-07-16

### Producto (commit `462802c9e`)

- Integración Spectra Flow: comando `@documentos`, API documentos, adjuntos desde Spectra.
- Imagen CI: `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6`.

### Sin cambios en este período

- Sin deploy documentado desde el repositorio.
- Sin modificación de producción verificada.

---

## Sprint 0 — Documentación y baseline — 2026-07-23

### Added

- `docs/optimia/` — 19 archivos: arquitectura, operaciones, seguridad, inventario, ADRs, upgrades.
- Remote `upstream` → `chatwoot/chatwoot`.
- Tag `chatwoot-base/v4.10.1` → `6a7cbcf5`.
- Protocolo continuidad: `docs/project/`, `.cursor/rules/00-session-continuity.mdc`, `scripts/project-context.sh`.
- Checklist EasyPanel: `docs/optimia/operations/easypanel-production-checklist.md`.

### Changed

- `AGENTS.md` — sección OptimiA continuidad entre sesiones.

### Commits

- `5ab2bb5e4` — `docs(optimia): establish deployment traceability and security baseline`
- *(continuidad)* — `docs(project): add cross-session continuity protocol`

### Validaciones

- Commit Sprint 0: solo documentación, sin secretos, sin código funcional.
- YAML workflows: 16/16 válidos.
- `pnpm audit`: 129 vulnerabilidades (no remediadas en Sprint 0).

### Deploy

- Ninguno.

---

## Base Chatwoot 4.10.1

- Fork desde `6a7cbcf5` (2026-02-06).
- Primer commit OptimiA: `ac4ec0fbe`.
- 43 commits propios sobre baseline al cierre Sprint 0.
