# PROJECT-STATUS — OptimiA

> Fuente de verdad del estado del proyecto. Actualizar al cierre de cada sprint.  
> Última actualización: 2026-07-23 (cierre Sprint 0)

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
| Commit funcional previo | `462802c9e` | Optimia Inbox v0.1.2 — último cambio de producto |
| Commit Sprint 0 (docs) | `5ab2bb5e4` | Trazabilidad, baseline y seguridad |
| Commit continuidad | *(ver `git log -1` tras push)* | Protocolo cross-session |
| Baseline fork | `6a7cbcf5` | Último commit upstream antes de personalizaciones OptimiA |
| Tag baseline | `chatwoot-base/v4.10.1` → `6a7cbcf5` | No equivale al tag release upstream `v4.10.1` (`1345f679`) |

## Remotes

| Remote | URL |
|--------|-----|
| `origin` | `https://github.com/pablo-paez-dev/chatwoot` |
| `upstream` | `https://github.com/chatwoot/chatwoot.git` |

## Desfase upstream (verificado Sprint 0)

| Métrica | Valor |
|---------|-------|
| Adelante de `upstream/develop` | 43 commits (OptimiA) |
| Detrás de `upstream/develop` | 713 commits |

## Entornos

| Entorno | Estado |
|---------|--------|
| **Producción** | PENDIENTE DE TRAZABILIDAD EASYPANEL |
| **Staging** | NO VERIFICADO |
| **Dominio esperado** | `https://app.optimia.spectra-metrics.com` (referencia CI, no confirmado en EasyPanel) |

## Infraestructura

| Componente | Estado |
|------------|--------|
| **Worker Sidekiq** | PENDIENTE DE VERIFICACIÓN en EasyPanel |
| **Imagen productiva** | PENDIENTE DE VERIFICACIÓN EN EASYPANEL |
| **Imagen detectada en CI** | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` *(no asumir desplegada)* |
| **Tag flotante CI** | `ghcr.io/disruptive-dev/chatwoot:optimia-latest` *(no usar en prod)* |

## Sprints

| Sprint | Estado | Commit principal |
|--------|--------|------------------|
| Sprint 0 — Trazabilidad y baseline | **FINALIZADO** | `5ab2bb5e4` + continuidad |
| Sprint 1 — Inventario EasyPanel y normalización | **PENDIENTE** | — |

## ADRs

| ADR | Tema | Estado |
|-----|------|--------|
| ADR-001 | Repositorio canónico | PROPUESTA — pendiente decisión propietario |
| ADR-002 | Estrategia de contenedores | PROPUESTA — pendiente decisión propietario |
| ADR-003 | Estrategia de versionado | PROPUESTA — pendiente decisión propietario |

## Bloqueos actuales

1. Trazabilidad EasyPanel no verificada — completar `docs/optimia/operations/easypanel-production-checklist.md`.
2. Worker Sidekiq en producción no confirmado.
3. ADRs sin aprobación del propietario.

## Próximo paso exacto

**El usuario debe completar el checklist manual de EasyPanel** (`docs/optimia/operations/easypanel-production-checklist.md`) y enviar los datos (sin secretos). No iniciar cambios funcionales hasta recibir esa información.

## Documentación clave

- `docs/optimia/` — documentación técnica OptimiA
- `docs/project/SPRINT-HANDOFF.md` — historial de sprints
- `docs/project/DECISIONS.md` — decisiones registradas
- `scripts/project-context.sh` — diagnóstico rápido (solo lectura)
