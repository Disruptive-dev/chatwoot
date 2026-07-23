# PROJECT-STATUS — OptimiA

> Fuente de verdad del estado del proyecto. Actualizar al cierre de cada sprint.  
> Última actualización: 2026-07-23 (Sprint 1 — preparación staging)

## Identidad

| Campo | Valor |
|-------|-------|
| **Proyecto** | OptimiA |
| **Base** | Chatwoot |
| **Versión Chatwoot** | 4.10.1 |
| **Versión OptimiA** | 0.1.2 |
| **Repositorio actual** | `pablo-paez-dev/chatwoot` |
| **Repositorio canónico futuro** | `DSW-Factory/optimia-chatwoot` (ADR-001 — pendiente aprobación) |
| **Rama activa** | `develop` |

## Commits de referencia

| Referencia | SHA | Descripción |
|------------|-----|-------------|
| Commit funcional | `462802c9e` | Optimia Inbox v0.1.2 |
| Sprint 0 docs | `5ab2bb5e4` | Trazabilidad y baseline |
| Sprint 0 continuidad | `86d316283` | Protocolo cross-session |
| Sprint 1 staging | *(ver `git log -1` tras commit)* | Preparación staging aislado |
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

## Staging

| Campo | Estado |
|-------|--------|
| **Entorno** | NO CREADO — documentación lista |
| **Dominio propuesto** | `https://staging.optimia.spectra-metrics.com` |
| **Imagen propuesta** | `ghcr.io/disruptive-dev/chatwoot:staging-cw-4.10.1-optimia-0.1.2` |
| **Workflow build** | `build-optimia-chatwoot-staging.yml` (manual, no afecta prod) |
| **Guía EasyPanel** | `docs/optimia/operations/easypanel-staging-setup-guide.md` |

## Sprints

| Sprint | Estado |
|--------|--------|
| Sprint 0 — Trazabilidad y baseline | **FINALIZADO** |
| Sprint 1 — Preparación staging aislado | **EN CURSO / PREPARACIÓN** (sin deploy) |
| Sprint 1b — Creación staging EasyPanel | **PENDIENTE** (acción humana) |

## ADRs

| ADR | Estado |
|-----|--------|
| ADR-001, 002, 003 | PROPUESTA — pendiente decisión propietario |

## Bloqueos

1. Staging no desplegado — requiere acción humana en EasyPanel.
2. Imagen staging debe publicarse vía workflow manual antes del deploy.
3. ADRs sin aprobación formal.

## Próximo paso exacto

1. Revisar y aprobar commit Sprint 1 en repo (push si autorizado).
2. Disparar manualmente `Build Optimia Chatwoot Staging Image` en GitHub Actions.
3. Operador crea proyecto staging en EasyPanel siguiendo la guía — **sin tocar prod**.

## Documentación clave

- Staging: `docs/optimia/environments/`
- Guía EasyPanel staging: `docs/optimia/operations/easypanel-staging-setup-guide.md`
- Handoff: `docs/project/SPRINT-HANDOFF.md`
