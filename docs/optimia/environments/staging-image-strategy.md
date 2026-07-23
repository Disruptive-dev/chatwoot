# Estrategia de imágenes — Staging OptimiA

## Regla de oro

| Entorno | Tag | Modificable |
|---------|-----|-------------|
| **Producción** | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` | **NO** — congelado |
| **Staging** | Tags con prefijo `staging-` | Sí — solo staging |

**Nunca** desplegar `optimia-latest` ni tags de producción en staging sin revisión explícita.

## Registry

Mismo registry que producción (transición):

```
ghcr.io/disruptive-dev/chatwoot
```

Futuro (ADR-001): `ghcr.io/dsw-factory/optimia-chatwoot`

## Formato de tags staging

Según [ADR-003](../adr/ADR-003-versioning-strategy.md), adaptado para staging:

```
ghcr.io/disruptive-dev/chatwoot:staging-cw-4.10.1-optimia-0.1.2
```

| Componente | Valor |
|------------|-------|
| Prefijo | `staging-` — distingue de prod |
| Chatwoot base | `cw-4.10.1` |
| OptimiA | `optimia-0.1.2` |

### Tags adicionales (opcionales, no para prod)

| Tag | Uso |
|-----|-----|
| `staging-cw-4.10.1-optimia-0.1.2` | **Inmutable** — usar en EasyPanel staging |
| `staging-latest` | Solo desarrollo interno — **no** usar en EasyPanel sin confirmar |

## Imagen inicial de staging (bootstrap)

Para el **primer** despliegue de staging, opciones en orden de preferencia:

### Opción A — Tag staging dedicado (recomendado)

1. Disparar workflow manual `Build Optimia Chatwoot Staging Image`.
2. Publica `staging-cw-4.10.1-optimia-0.1.2` desde commit actual de `develop`.
3. Desplegar ese tag en EasyPanel staging.

**Ventaja:** `FRONTEND_URL` de build apunta a dominio staging.

### Opción B — Misma capa que prod, distinto runtime ENV

Usar temporalmente `v4.10.1-optimia.6` en staging **solo** si:
- `FRONTEND_URL` se sobrescribe en runtime (ENV EasyPanel) a dominio staging.
- Se acepta que assets pueden referenciar URL de build prod (`app.optimia.spectra-metrics.com`).

**Desventaja:** branding/URLs baked en assets pueden apuntar a prod. **Opción A es preferible.**

## Workflow CI

| Workflow | Trigger | Tags producidos | Afecta prod |
|----------|---------|-----------------|-------------|
| `build-optimia-chatwoot.yml` | Push `develop` + manual | `v4.10.1-optimia.6`, `optimia-latest` | Sí (prod CI) — **no modificar** |
| `build-optimia-chatwoot-staging.yml` | **Solo manual** (`workflow_dispatch`) | `staging-cw-4.10.1-optimia-0.1.2` | **No** |

### Build args staging (workflow)

| ARG | Valor staging |
|-----|---------------|
| `SECRET_KEY_BASE` | `dummy_secret_key_base_for_assets` (solo precompile) |
| `FRONTEND_URL` | `https://staging.optimia.spectra-metrics.com` |
| `INSTALLATION_NAME` | `OptimIA Staging` |
| `BRAND_NAME` | `OptimIA` |

## Promoción staging → producción

```
1. Validar en staging con tag staging-cw-X.Y.Z-optimia-A.B.C
2. Si OK: build prod workflow genera tag prod inmutable (futuro: sin reutilizar staging tag)
3. Promover MISMO código (commit SHA), no necesariamente misma etiqueta Docker
4. Nunca renombrar tag staging como tag prod
```

## Rollback staging

Re-deploy del tag staging anterior en EasyPanel. Sin impacto en producción.

## Checklist pre-build staging

- [ ] Workflow staging disparado manualmente (no automático en push).
- [ ] Tag contiene prefijo `staging-`.
- [ ] `FRONTEND_URL` build arg = dominio staging.
- [ ] Tag prod `v4.10.1-optimia.6` no modificado.

## Checklist pre-deploy EasyPanel staging

- [ ] Tag en servicio web = tag staging (no `v4.10.1-optimia.6` salvo Opción B consciente).
- [ ] Worker usa **exactamente** el mismo tag.
- [ ] Proyecto EasyPanel ≠ proyecto producción.
