# Migración de Registry — GHCR

## Estado actual (2026-07-26)

| Namespace | Uso | Estado |
|-----------|-----|--------|
| `ghcr.io/disruptive-dev/chatwoot` | Prod v0.1.9 desplegada | **Congelado** — no usar en CI |
| `ghcr.io/pablo-paez-dev/chatwoot` | Staging + nuevos builds | **Activo (fallback)** |
| `ghcr.io/dsw-factory/optimia-chatwoot` | Objetivo ADR-001 | **Pendiente** permisos |

## Verificación DSW-Factory

```bash
gh api orgs/DSW-Factory          # Org existe
# Publish cross-org requiere GHCR_TOKEN con write:packages en org
```

`GITHUB_TOKEN` del repo `pablo-paez-dev/chatwoot` publica solo en namespace del actor/repo.

## Pasos para migrar

### 1. Preparar org DSW-Factory

- [ ] Crear repo `DSW-Factory/optimia-chatwoot` (futuro — ADR-001)
- [ ] Crear PAT fine-grained o GitHub App:
  - Scope: `write:packages`, `read:packages`
  - Resource owner: `DSW-Factory`
- [ ] Guardar como `GHCR_TOKEN` en secrets org/repo

### 2. Crear package GHCR

Primer push crea el package automáticamente:

```
ghcr.io/dsw-factory/optimia-chatwoot:staging-cw-4.10.1-optimia-0.2.0
```

Vincular package al repositorio en GitHub Packages settings.

### 3. Actualizar variable

```
OPTIMIA_GHCR_REGISTRY=ghcr.io/dsw-factory/optimia-chatwoot
```

### 4. Validar

```bash
# Staging dry-run primero
# workflow_dispatch con registry override

bash scripts/optimia/image-inspect.sh ghcr.io/dsw-factory/optimia-chatwoot:staging-cw-4.10.1-optimia-0.2.0
```

### 5. Transición producción

1. Publicar v0.2.0 en nuevo registry (staging → prod)
2. Deploy staging con nuevo digest
3. Smoke tests
4. Promover a producción
5. Mantener `disruptive-dev` 90 días para rollback

## Matriz de migración

| Fase | Registry CI | Prod desplegada | Acción |
|------|-------------|-----------------|--------|
| **Actual** | `pablo-paez-dev` (nuevo) / `disruptive-dev` (legacy CI) | `disruptive-dev` v0.1.9 | CI cleanup v0.2.1 |
| **v0.2.0 publish** | `pablo-paez-dev` | `disruptive-dev` v0.1.9 | Staging nuevo digest |
| **Post-DSW** | `dsw-factory` | Migrar manual EasyPanel | Requiere GHCR_TOKEN |

## Sin credenciales inventadas

Si `GHCR_TOKEN` no está disponible, **mantener** `ghcr.io/pablo-paez-dev/chatwoot`. La arquitectura está parametrizada vía `OPTIMIA_GHCR_REGISTRY`.
