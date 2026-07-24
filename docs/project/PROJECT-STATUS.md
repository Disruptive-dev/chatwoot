# PROJECT-STATUS — OptimiA

> Fuente de verdad del estado del proyecto. Actualizar al cierre de cada sprint.  
> Última actualización: 2026-07-24 (Sprint 3 — Technical Health Center v0.2.0)

## Identidad

| Campo | Valor |
|-------|-------|
| **Proyecto** | OptimiA |
| **Base** | Chatwoot |
| **Versión Chatwoot** | 4.10.1 |
| **Versión OptimiA** | 0.2.0 |
| **Repositorio actual** | `pablo-paez-dev/chatwoot` |
| **Repositorio canónico futuro** | `DSW-Factory/optimia-chatwoot` (ADR-001 — pendiente aprobación) |
| **Rama activa** | `cursor/technical-health-center-3da0` |

## Commits de referencia

| Referencia | SHA | Descripción |
|------------|-----|-------------|
| Commit funcional | `462802c9e` | Optimia Inbox v0.1.2 |
| Sprint 0 docs | `5ab2bb5e4` | Trazabilidad y baseline |
| Sprint 0 continuidad | `86d316283` | Protocolo cross-session |
| Sprint 1 staging | `c3537990d` | Preparación staging aislado |
| Sprint 2 Connection Center | *(ver `git log`)* | Channel Manager + WhatsApp Connection Center |
| Sprint 3 Technical Health | *(ver `git log` tras commit)* | Technical Health Center v0.2.0 |
| Baseline fork | `6a7cbcf5` | Último upstream antes de OptimiA |
| Tag baseline | `chatwoot-base/v4.10.1` → `6a7cbcf5` | Publicado en origin |

## Producción (verificado — NO MODIFICAR)

| Componente | Valor |
|------------|-------|
| Imagen | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Web | `chatwoot` |
| Worker | `chatwoot-sidekiq` (misma imagen, Sidekiq operativo) |
| PostgreSQL | `chatwoot-db` |
| Redis | `chatwoot-redis` |
| Dominio | `https://app.optimia.spectra-metrics.com` |
| Estado | Clientes reales, operativo |
| Versión OptimiA prod | 0.1.x (sin Technical Health Center) |

## Staging

| Campo | Estado |
|-------|--------|
| **Entorno** | NO CREADO — documentación lista |
| **Dominio propuesto** | `https://staging.optimia.spectra-metrics.com` |
| **Imagen propuesta** | `ghcr.io/disruptive-dev/chatwoot:staging-cw-4.10.1-optimia-0.2.0` |
| **Workflow build** | `build-optimia-chatwoot-staging.yml` (manual, no afecta prod) |
| **Guía EasyPanel** | `docs/optimia/operations/easypanel-staging-setup-guide.md` |

## Sprints

| Sprint | Estado |
|--------|--------|
| Sprint 0 — Trazabilidad y baseline | **FINALIZADO** |
| Sprint 1 — Preparación staging aislado | **FINALIZADO** (sin deploy) |
| Sprint 1b — Creación staging EasyPanel | **PENDIENTE** (acción humana) |
| Sprint 2 — Channel Manager + Connection Center | **IMPLEMENTADO** (pendiente staging QA) |
| Sprint 3 — Technical Health Center v0.2.0 | **IMPLEMENTADO** (pendiente staging QA) |

## ADRs

| ADR | Estado |
|-----|--------|
| ADR-001, 002, 003 | PROPUESTA — pendiente decisión propietario |
| ADR-004 | ACEPTADO — Channel Manager foundation |

## Bloqueos

1. Staging no desplegado — requiere acción humana en EasyPanel.
2. Imagen staging debe publicarse vía workflow manual antes del deploy.
3. ADRs 001-003 sin aprobación formal.
4. Sprint 2 y 3 requieren validación en staging (Evolution API + Technical Health + smoke tests).
5. Migración BD Technical Health pendiente hasta deploy staging.

## Próximo paso exacto

1. Merge `cursor/technical-health-center-3da0` → `develop` y build imagen staging v0.2.0.
2. Ejecutar migración BD en staging.
3. Configurar ENV (`OPTIMIA_INTERNAL_HEALTH_TOKEN`, Evolution, deploy metadata).
4. Smoke tests: `docs/optimia/technical-health/runbooks.md` y `docs/optimia/operations/staging-connection-center-runbook.md`.

## Documentación clave

- Technical Health Center: `docs/optimia/technical-health/`
- Staging: `docs/optimia/environments/`
- Guía EasyPanel staging: `docs/optimia/operations/easypanel-staging-setup-guide.md`
- Handoff: `docs/project/SPRINT-HANDOFF.md`
- Channel Manager RFC: `docs/optimia/architecture/channel-manager-rfc.md`
- Connection Center runbook: `docs/optimia/operations/staging-connection-center-runbook.md`
