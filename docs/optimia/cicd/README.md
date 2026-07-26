# OptimiA CI/CD

> Pipeline unificado v0.2.1 — Sprint CI/CD Platform Cleanup

## Resumen

| Workflow | Archivo | Trigger | Publica imagen |
|----------|---------|---------|----------------|
| **CI** | `optimia-ci.yml` | PR/push `develop` | No |
| **Staging** | `optimia-build-staging.yml` | Manual, tag `staging-cw-*` | Sí (staging) |
| **Producción** | `optimia-build-production.yml` | Solo manual + aprobación | Sí (prod) |

## Registry

| Estado | Valor |
|--------|-------|
| Objetivo | `ghcr.io/dsw-factory/optimia-chatwoot` |
| **Activo (fallback)** | `ghcr.io/pablo-paez-dev/chatwoot` |
| Prohibido en CI | `ghcr.io/disruptive-dev/chatwoot` |

Variable: `OPTIMIA_GHCR_REGISTRY` (GitHub Settings → Variables)

### Bloqueo DSW-Factory

La org `DSW-Factory` existe pero el `GITHUB_TOKEN` del repo no publica cross-org. Para migrar:

1. Crear PAT o GitHub App con `write:packages` en org `DSW-Factory`
2. Guardar como secret `GHCR_TOKEN` (repo u org)
3. Actualizar `OPTIMIA_GHCR_REGISTRY=ghcr.io/dsw-factory/optimia-chatwoot`

## Tags

```
Staging:     staging-cw-4.10.1-optimia-0.2.0
Producción:  cw-4.10.1-optimia-0.2.0
```

EasyPanel **siempre** usa digest `sha256:...`, nunca `latest`.

## Variables requeridas (GitHub)

| Variable | Default |
|----------|---------|
| `OPTIMIA_GHCR_REGISTRY` | `ghcr.io/pablo-paez-dev/chatwoot` |
| `OPTIMIA_FRONTEND_URL_STAGING` | `https://staging.optimia.spectra-metrics.com` |
| `OPTIMIA_FRONTEND_URL_PRODUCTION` | `https://app.optimia.spectra-metrics.com` |
| `OPTIMIA_CHATWOOT_BASE_VERSION` | `4.10.1` |
| `OPTIMIA_INSTALLATION_NAME` | `OptimiA` |
| `OPTIMIA_BRAND_NAME` | `OptimiA` |

## Secretos

| Secret | Requerido | Notas |
|--------|-----------|-------|
| `GITHUB_TOKEN` | Automático | Publish mismo namespace que repo |
| `GHCR_TOKEN` | Solo cross-org | Migración a DSW-Factory |

### Obsoletos (no eliminar este sprint)

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`

## Environment `production`

Configurar en GitHub → Settings → Environments → `production`:

- Required reviewers (mínimo 1)
- Sin secrets de deploy EasyPanel en CI

## Scripts

```bash
# Validar configuración pipeline (15 checks)
bash scripts/optimia/validate-cicd.sh

# Estado último run CI
bash scripts/optimia/ci-status.sh optimia-ci.yml

# Inspeccionar digest
bash scripts/optimia/image-inspect.sh ghcr.io/pablo-paez-dev/chatwoot:staging-cw-4.10.1-optimia-0.2.0

# Metadata release
bash scripts/optimia/release-metadata.sh 0.2.0
```

## Documentación

| Documento | Contenido |
|-----------|-----------|
| [constitution.md](./constitution.md) | Principios inmutables |
| [spec.md](./spec.md) | Especificación técnica |
| [decisions.md](./decisions.md) | ADR-001 a ADR-004 |
| [plan.md](./plan.md) | Plan de implementación |
| [tasks.md](./tasks.md) | Checklist tareas |
| [runbook-staging.md](./runbook-staging.md) | Publicar staging |
| [runbook-production.md](./runbook-production.md) | Publicar producción |
| [rollback.md](./rollback.md) | Rollback por digest |
| [registry-migration.md](./registry-migration.md) | Migración DSW-Factory |

## Workflows upstream deshabilitados en fork

Guard `github.repository == 'chatwoot/chatwoot'`:

- `publish_foss_docker.yml`, `publish_ee_docker.yml`
- `deploy_check.yml`, `nightly_installer.yml`, `stale.yml`
- `logging_percentage_check.yml`, `frontend-fe.yml`
- `run_foss_spec.yml`, `test_docker_build.yml`
- `publish_codespace_image.yml`

## Confirmación

Este pipeline **no despliega** a EasyPanel. Build y publish de imagen únicamente.
