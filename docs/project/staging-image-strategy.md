# Estrategia de imágenes — Staging OptimiA

> Actualizado v0.2.1 CI/CD cleanup. Ver también `docs/optimia/cicd/`.

## Regla de oro

| Entorno | Tag / Imagen | Modificable |
|---------|--------------|-------------|
| **Producción** | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` (v0.1.9 desplegada) | **NO** — congelado |
| **Staging** | `staging-cw-4.10.1-optimia-0.2.0` | Sí — solo staging |

EasyPanel **siempre** usa digest `sha256:...`, nunca `latest`.

## Registry activo (CI v0.2.1)

| Estado | Registry |
|--------|----------|
| **Activo** | `ghcr.io/pablo-paez-dev/chatwoot` |
| **Objetivo** | `ghcr.io/dsw-factory/optimia-chatwoot` |
| **Legacy prod** | `ghcr.io/disruptive-dev/chatwoot` (solo imagen v0.1.9 desplegada) |

Variable: `OPTIMIA_GHCR_REGISTRY`

## Formato tags

```
Staging:     staging-cw-4.10.1-optimia-0.2.0
Producción:  cw-4.10.1-optimia-0.2.0
```

## Workflow

| Workflow | Trigger | Afecta prod |
|----------|---------|-------------|
| `optimia-build-staging.yml` | Manual, tag `staging-cw-*` | **No** |
| `optimia-build-production.yml` | Solo manual + aprobación | Solo si aprobado |

Workflows legacy `build-optimia-chatwoot*.yml` → **deprecados**.

## Publicar v0.2.0 staging

1. Merge CI/CD cleanup PR
2. Tag: `staging-cw-4.10.1-optimia-0.2.0`
3. Copiar digest del job summary
4. Deploy manual EasyPanel staging

Ver: [runbook-staging.md](../optimia/cicd/runbook-staging.md)
