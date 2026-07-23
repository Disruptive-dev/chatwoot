# ADR-002: Estrategia de contenedores OptimiA

| Campo | Valor |
|-------|-------|
| Estado | **PROPUESTA — PENDIENTE DE APROBACIÓN** |
| Fecha | 2026-07-23 |
| Relacionado | [docker-v2-rfc.md](../architecture/docker-v2-rfc.md) |

## Contexto

Estado actual (Sprint 0):
- `Dockerfile` raíz: single-stage, solo `rails server`, usuario root, sin HEALTHCHECK.
- `docker/Dockerfile`: oficial upstream multi-stage Alpine, no usado en CI OptimiA.
- CI publica imagen única sin distinción web/worker.
- `docker-compose.production.yaml` referencia `chatwoot/chatwoot:latest` (oficial, no OptimiA).

## Decisión propuesta

1. **Imagen única**, dos servicios (web + worker) con comandos distintos.
2. Basada en `docker/Dockerfile` oficial (multi-stage Alpine).
3. Usuario non-root.
4. HEALTHCHECK en web.
5. Migraciones como release job separado.
6. Tags inmutables en GHCR.

## Arquitectura de contenedores

```
┌─────────────────────────────────────────────┐
│  ghcr.io/dsw-factory/optimia-chatwoot:TAG   │
│  (imagen única, multi-stage Alpine)         │
├──────────────────┬──────────────────────────┤
│  optimia-web     │  optimia-worker          │
│  rails server    │  sidekiq                 │
│  :3000 /health   │  sin puerto              │
└──────────────────┴──────────────────────────┘
```

## Comparación

| Aspecto | Dockerfile actual | Propuesta v2 |
|---------|-------------------|--------------|
| Base image | `ruby:3.4.4-slim` (Debian) | `ruby:3.4.4-alpine3.21` |
| Stages | 1 | 2+ (pre-builder + runtime) |
| Tamaño | Grande (dev deps incluidas) | Optimizado |
| Usuario | root | `optimia` (UID 1000) |
| HEALTHCHECK | No | `GET /health` |
| Sidekiq | No incluido | Comando separado |
| Migraciones | No | Release job externo |
| Secretos en capas | ENV baked | Solo runtime ENV |

## Release job (migraciones)

```bash
# Ejecutar UNA vez antes de deploy, no en cada restart
POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
```

Equivalente al `release` en `Procfile`:
```
release: POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
```

## Compatibilidad EasyPanel

| Requisito | Cumplimiento |
|-----------|--------------|
| Un servicio = un contenedor | ✅ Web y worker como servicios separados |
| Misma imagen, distinto comando | ✅ |
| Puerto 3000 | ✅ Web |
| Healthcheck HTTP | ✅ `/health` |
| Volúmenes storage | ✅ Montaje externo `/app/storage` |
| ENV en runtime | ✅ No baked secrets |

## Transición

1. Implementar `docker/Dockerfile.optimia` (Sprint 1–2).
2. Probar build local sin push.
3. Publicar tag de prueba en staging.
4. Validar web + worker + migraciones.
5. Deprecar `Dockerfile` raíz (renombrar a `.legacy`).
6. Actualizar `build-optimia-chatwoot.yml`.

## Rollback de imagen

Re-deploy del tag anterior en web y worker. Sin rebuild.

## Consecuencias

- Requiere servicio worker explícito en EasyPanel (si no existe, crearlo).
- Imagen Alpine puede tener diferencias de comportamiento vs Debian (libvips, etc.) — validar en staging.
- Build inicial más complejo pero reproducible.

## Estado

```
PROPUESTA — PENDIENTE DE APROBACIÓN
```

Implementación detallada en [docker-v2-rfc.md](../architecture/docker-v2-rfc.md).
