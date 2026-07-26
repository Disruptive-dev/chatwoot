# OptimiA CI/CD — Decisiones (ADR)

> Sprint: v0.2.1 CI/CD Platform Cleanup  
> Fecha: 2026-07-26

---

## ADR-001 — Registry canónico

| Campo | Valor |
|-------|-------|
| **Estado** | **ACEPTADO** (implementación con fallback) |
| **Fecha** | 2026-07-26 |

### Contexto

Producción v0.1.9 usa `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` (congelada). CI intentaba publicar ahí sin permisos. Staging publicaba en `ghcr.io/pablo-paez-dev/chatwoot`. La org `DSW-Factory` existe en GitHub.

### Verificación realizada

```bash
gh api orgs/DSW-Factory          # → OK (org existe)
gh api user/orgs                 # → 403 (token sin scope org list)
```

`GITHUB_TOKEN` del repo `pablo-paez-dev/chatwoot` **no puede** publicar cross-org a `ghcr.io/dsw-factory/` sin `GHCR_TOKEN` con permisos `write:packages` en la org.

### Decisión

| Prioridad | Registry |
|-----------|----------|
| **Objetivo** | `ghcr.io/dsw-factory/optimia-chatwoot` |
| **Fallback activo** | `ghcr.io/pablo-paez-dev/chatwoot` |
| **Prohibido** | `ghcr.io/disruptive-dev/chatwoot` |

Parametrizar vía variable `OPTIMIA_GHCR_REGISTRY`. Migrar a DSW-Factory cuando exista `GHCR_TOKEN` org-level.

### Consecuencias

- Imagen prod v0.1.9 en `disruptive-dev` permanece intacta.
- Nuevos builds usan fallback hasta migración.
- Package debe vincularse al repo al primer publish exitoso.

---

## ADR-002 — Estrategia de CI

| Campo | Valor |
|-------|-------|
| **Estado** | **ACEPTADO** |
| **Fecha** | 2026-07-26 |

### Decisión

Un único workflow de CI: `.github/workflows/optimia-ci.yml`

### Jobs incluidos

1. backend-lint
2. backend-tests (4 nodos, no 16)
3. frontend-lint
4. frontend-tests
5. docker-build-test
6. zeitwerk
7. optimia-channel-manager-tests
8. optimia-technical-health-tests

### Workflows upstream CI

`run_foss_spec.yml`, `frontend-fe.yml`, `test_docker_build.yml` reciben guard `github.repository == 'chatwoot/chatwoot'` para no duplicar en el fork.

### Conservados sin guard

- `lint_pr.yml`
- `size-limit.yml`
- `auto-assign-pr.yml`

---

## ADR-003 — Versionado y tags

| Campo | Valor |
|-------|-------|
| **Estado** | **ACEPTADO** |
| **Fecha** | 2026-07-26 |

### Esquema

| Entorno | Tag | Ejemplo v0.2.0 |
|---------|-----|----------------|
| Staging | `staging-cw-{cw}-optimia-{opt}` | `staging-cw-4.10.1-optimia-0.2.0` |
| Producción | `cw-{cw}-optimia-{opt}` | `cw-4.10.1-optimia-0.2.0` |
| Referencia opcional | `production-latest` | No usar en EasyPanel |

### Reglas

- EasyPanel **siempre** usa digest SHA-256 inmutable.
- Tags flotantes (`optimia-latest`, `latest`) prohibidos en deploy prod.
- Tag de producción no se sobrescribe; workflow falla si existe.

### Migración desde esquema legacy

| Legacy | Nuevo |
|--------|-------|
| `v4.10.1-optimia.6` | `cw-4.10.1-optimia-0.1.9` (futuro) |
| `optimia-latest` | Deprecado |

---

## ADR-004 — Promoción a producción

| Campo | Valor |
|-------|-------|
| **Estado** | **ACEPTADO** |
| **Fecha** | 2026-07-26 |

### Decisión

Producción solo mediante:

1. `workflow_dispatch` en `optimia-build-production.yml`
2. Environment `production` con required reviewer
3. Input `confirm_production` = `DEPLOY_OPTIMIA`
4. Input `staging_digest` con digest previamente validado
5. Imagen staging validada antes de promoción

### Prohibido

- Push automático a `develop` que publique producción
- Deploy automático a EasyPanel
- Sobrescribir tags de producción existentes
- Publicar sin aprobación manual

### Flujo

```
staging build → smoke tests → aprobación humana → production workflow → digest en summary → deploy manual EasyPanel
```
