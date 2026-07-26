# OptimiA CI/CD — Especificación técnica v0.2.1

## 1. Inventario workflows (auditoría 2026-07-26)

| Archivo | Nombre | Trigger | Destino | Clasificación | Riesgo | Acción |
|---------|--------|---------|---------|---------------|--------|--------|
| `build-optimia-chatwoot.yml` | Build Optimia Chatwoot Image | push develop, manual | `ghcr.io/disruptive-dev/chatwoot` | OptimiA prod | **Alto** | **Reemplazar** → `optimia-build-production.yml` |
| `build-optimia-chatwoot-staging.yml` | Build Staging | manual, tag `staging-cw-*` | `ghcr.io/pablo-paez-dev/chatwoot` | OptimiA staging | Medio | **Reemplazar** → `optimia-build-staging.yml` |
| `run_foss_spec.yml` | Run Chatwoot CE spec | push/PR develop | N/A | Upstream CI | Medio (16 nodos) | **Guard** upstream |
| `frontend-fe.yml` | Frontend Lint & Test | push/PR develop | N/A | Upstream duplicado | Medio | **Guard** upstream |
| `test_docker_build.yml` | Test Docker Build | PR develop | N/A (no push) | Upstream CI | Bajo | **Guard** upstream |
| `publish_foss_docker.yml` | Publish CE Docker | push develop, tags | Docker Hub `chatwoot/chatwoot` | Upstream innecesario | **Crítico** | **Guard** upstream |
| `publish_ee_docker.yml` | Publish EE Docker | push develop, tags | Docker Hub | Upstream innecesario | **Crítico** | **Guard** upstream |
| `publish_codespace_image.yml` | Codespace image | manual | `ghcr.io/chatwoot/chatwoot_codespace` | Upstream manual | Bajo | **Guard** upstream |
| `deploy_check.yml` | Deploy Check | PR | Heroku review apps | Upstream innecesario | **Alto** | **Guard** upstream |
| `nightly_installer.yml` | Nightly installer | cron diario | N/A | Upstream cron | Medio | **Guard** upstream |
| `stale.yml` | Mark stale PRs | cron diario | N/A | Upstream cron | Medio | **Guard** upstream |
| `logging_percentage_check.yml` | Log lines % | PR develop | N/A | Upstream innecesario | Bajo | **Guard** upstream |
| `size-limit.yml` | Size Limit | PR develop | N/A | Upstream útil | Bajo | **Mantener** |
| `lint_pr.yml` | Lint PR | PR | N/A | Upstream útil | Bajo | **Mantener** |
| `auto-assign-pr.yml` | Auto-assign | PR opened | N/A | Upstream útil | Bajo | **Mantener** |
| `lock.yml` | Lock threads | cron | N/A | Upstream (ya guardado) | Nulo | **Mantener** |
| `run_mfa_spec.yml` | MFA tests | PR (guardado) | N/A | Upstream | Nulo | **Mantener** |

## 2. Referencias auditadas

### `disruptive-dev` (activas en ejecución — a eliminar)

- `.github/workflows/build-optimia-chatwoot.yml` — **CRÍTICO**
- `scripts/staging-war-room.sh`
- Múltiples docs (histórico prod v0.1.9)

### `pablo-paez-dev`

- Remote `origin`
- `.github/workflows/build-optimia-chatwoot-staging.yml` — registry staging real
- **Fallback activo** en nuevos workflows

### `dsw-factory` / `DSW-Factory`

- Org GitHub existe (`gh api orgs/DSW-Factory` → OK)
- Publish cross-org **no verificado** (token integración sin permisos org)
- Solo documentación hasta configurar `GHCR_TOKEN`

### Docker Hub

- `publish_foss_docker.yml`, `publish_ee_docker.yml` — **deshabilitados con guard**

### Heroku

- `deploy_check.yml` — **deshabilitado con guard**

### Codespaces

- `publish_codespace_image.yml` — guard upstream
- `.devcontainer/` — sin cambios este sprint

## 3. Workflow `optimia-ci.yml`

### Triggers

```yaml
on:
  pull_request:
    branches: [develop]
  push:
    branches: [develop]
  workflow_dispatch:
```

### Concurrency

```yaml
concurrency:
  group: optimia-ci-${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: ${{ github.event_name == 'pull_request' }}
```

### Jobs

| Job | Timeout | Descripción |
|-----|---------|-------------|
| `backend-lint` | 15 min | `bundle exec rubocop --parallel` |
| `backend-tests` | 45 min | RSpec 4 nodos (subset crítico) |
| `frontend-lint` | 15 min | `pnpm eslint` |
| `frontend-tests` | 20 min | `pnpm test:coverage` |
| `docker-build-test` | 30 min | Build amd64 sin push |
| `zeitwerk` | 10 min | `bundle exec rails zeitwerk:check` |
| `optimia-channel-manager-tests` | 25 min | Specs Channel Manager |
| `optimia-technical-health-tests` | 25 min | Specs Technical Health |
| `ci-summary` | 5 min | Resumen final |

### Restricciones

- Sin `packages: write`
- Sin secretos de producción
- Artifacts solo en fallo
- Cache: bundler, pnpm, docker buildx

## 4. Workflow `optimia-build-staging.yml`

### Triggers

- `workflow_dispatch` (inputs: version, frontend_url, registry, dry_run)
- `push` tags: `staging-cw-*`

### Concurrency

```yaml
concurrency:
  group: optimia-staging-build
  cancel-in-progress: false
```

### Validaciones

- Tag debe coincidir con `^staging-cw-[0-9]+\.[0-9]+\.[0-9]+-optimia-[0-9]+\.[0-9]+\.[0-9]+$`
- `dry_run=true` → build sin push

### Outputs

- Imagen única en registry parametrizado
- Digest SHA-256 en job summary
- Artifact `staging-image-metadata.json`
- SBOM (cyclonedx) si build exitoso

## 5. Workflow `optimia-build-production.yml`

### Triggers

- Solo `workflow_dispatch`
- Tag opcional futuro: `optimia/v*` (sin push develop)

### Environment

```yaml
environment: production
```

### Inputs obligatorios

| Input | Descripción |
|-------|-------------|
| `optimia_version` | SemVer OptimiA (ej. `0.2.0`) |
| `chatwoot_version` | Base Chatwoot (`4.10.1`) |
| `staging_digest` | Digest SHA-256 validado en staging |
| `confirm_production` | Debe ser exactamente `DEPLOY_OPTIMIA` |

### Validaciones

- `confirm_production != DEPLOY_OPTIMIA` → falla
- Tag `cw-{cw}-optimia-{opt}` no debe existir en registry
- No sobrescribir tags existentes

### Concurrency

```yaml
concurrency:
  group: optimia-production-build
  cancel-in-progress: false
```

## 6. Variables y secretos

### Variables (repo/org)

| Variable | Valor default | Uso |
|----------|---------------|-----|
| `OPTIMIA_GHCR_REGISTRY` | `ghcr.io/pablo-paez-dev/chatwoot` | Registry activo |
| `OPTIMIA_FRONTEND_URL_STAGING` | `https://staging.optimia.spectra-metrics.com` | Build staging |
| `OPTIMIA_FRONTEND_URL_PRODUCTION` | `https://app.optimia.spectra-metrics.com` | Build prod |
| `OPTIMIA_CHATWOOT_BASE_VERSION` | `4.10.1` | Tags |
| `OPTIMIA_INSTALLATION_NAME` | `OptimiA` | Build args |
| `OPTIMIA_BRAND_NAME` | `OptimiA` | Build args |

### Secretos

| Secret | Requerido | Cuándo |
|--------|-----------|--------|
| `GITHUB_TOKEN` | Sí (automático) | Publish mismo namespace que repo |
| `GHCR_TOKEN` | Solo cross-org | Publish a `dsw-factory` desde `pablo-paez-dev` |

### Obsoletos (no borrar este sprint)

- `DOCKERHUB_USERNAME`
- `DOCKERHUB_TOKEN`
- Cualquier secret de `disruptive-dev`

## 7. Matriz before/after

| Aspecto | Antes | Después |
|---------|-------|---------|
| Workflows activos build | 2 (prod auto + staging) | 2 (staging + prod manual) |
| Workflows CI | 3+ (foss, frontend-fe, docker) | 1 (`optimia-ci`) |
| Registry prod CI | `disruptive-dev` | Parametrizado (fallback `pablo-paez-dev`) |
| Registry staging | `pablo-paez-dev` | Mismo registry unificado |
| Push develop → prod image | **Sí** | **No** |
| Docker Hub publish | Posible en push | Guard upstream |
| Heroku deploy check | Cada PR | Guard upstream |
| Producción protegida | No | Environment + reviewer |
