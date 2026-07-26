# OptimiA CI/CD — Constitution

> Versión: 0.2.1  
> Fecha: 2026-07-26  
> Rama base: `develop`  
> Commit referencia: `1f224c885`

## Propósito

Esta constitución define los principios inmutables del pipeline CI/CD de OptimiA. Todo cambio que contradiga estos principios requiere ADR y aprobación explícita del propietario.

## Principios

1. **Un registry canónico** — Todas las imágenes OptimiA se publican en un único namespace GHCR parametrizado. Objetivo: `ghcr.io/dsw-factory/optimia-chatwoot`. Fallback operativo: `ghcr.io/pablo-paez-dev/chatwoot`.
2. **Prohibido `disruptive-dev` en ejecución activa** — El namespace legacy no se usa en workflows nuevos. Producción actual (`v0.1.9`) permanece congelada hasta migración manual.
3. **Tres workflows de pipeline** — Exactamente uno de CI, uno de staging y uno de producción para builds de imagen.
4. **Producción nunca automática** — Sin push a `develop` que publique producción. Solo `workflow_dispatch` + environment `production` + reviewer.
5. **Staging controlado** — Manual o tag `staging-cw-*`. Sin deploy automático.
6. **Sin Docker Hub upstream** — Ningún workflow del fork publica en `chatwoot/chatwoot`.
7. **Sin Heroku** — Review apps y deploy checks de upstream deshabilitados en el fork.
8. **Digest inmutable en deploy** — EasyPanel siempre referencia digest SHA-256, nunca `latest`.
9. **Mínimo privilegio** — `contents: read`, `packages: write` solo en workflows de build.
10. **No deploy desde CI** — El pipeline construye y publica imágenes; EasyPanel es acción humana.

## Alcance

| Incluido | Excluido |
|----------|----------|
| Workflows GitHub Actions | Deploy EasyPanel |
| GHCR publish (staging/prod manual) | Modificación producción v0.1.9 |
| Documentación y scripts operativos | Evolution API |
| Guards upstream | Self Healing, CRM, IA |

## Workflows autorizados (estado objetivo)

| Workflow | Rol |
|----------|-----|
| `optimia-ci.yml` | CI único |
| `optimia-build-staging.yml` | Build staging |
| `optimia-build-production.yml` | Build producción (manual) |
| `lint_pr.yml` | Convención PR |
| `size-limit.yml` | Límite bundle frontend |
| `auto-assign-pr.yml` | Asignación PR |
| `lock.yml` | Lock threads (solo upstream) |
| `run_mfa_spec.yml` | MFA (solo upstream) |

## Registry

| Estado | Valor |
|--------|-------|
| **Objetivo** | `ghcr.io/dsw-factory/optimia-chatwoot` |
| **Fallback activo** | `ghcr.io/pablo-paez-dev/chatwoot` |
| **Prohibido** | `ghcr.io/disruptive-dev/chatwoot` |
| **Bloqueo DSW-Factory** | Org existe; publish cross-org no verificado — requiere `GHCR_TOKEN` org |

## Tags

| Entorno | Formato | Ejemplo |
|---------|---------|---------|
| Staging | `staging-cw-{cw}-optimia-{opt}` | `staging-cw-4.10.1-optimia-0.2.0` |
| Producción | `cw-{cw}-optimia-{opt}` | `cw-4.10.1-optimia-0.2.0` |
| Opcional | `production-latest` | Solo referencia; no usar en EasyPanel |

## Confirmación de no-deploy

Este sprint **no despliega** staging ni producción. **No modifica** EasyPanel, servicios ni imágenes en ejecución.
