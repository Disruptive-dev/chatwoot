# Entornos OptimiA

Documentación por entorno. **Producción no se modifica desde este repositorio.**

| Entorno | Documento | Estado |
|---------|-----------|--------|
| Producción (referencia) | [`../architecture/current-state.md`](../architecture/current-state.md) | Verificado Sprint 1 |
| **Staging (aislado)** | [`staging-architecture.md`](staging-architecture.md) | Preparación Sprint 1 — sin desplegar |
| Objetivo futuro | [`../architecture/target-state.md`](../architecture/target-state.md) | ADR pendientes |

## Staging — índice Sprint 1

1. [`staging-architecture.md`](staging-architecture.md) — topología exacta
2. [`staging-image-strategy.md`](staging-image-strategy.md) — imágenes y tags
3. [`staging-variables.md`](staging-variables.md) — variables requeridas (sin secretos prod)
4. [`staging-web-worker-config.md`](staging-web-worker-config.md) — configuración web y worker
5. [`staging-isolation-controls.md`](staging-isolation-controls.md) — controles anti-producción
6. [`../operations/easypanel-staging-setup-guide.md`](../operations/easypanel-staging-setup-guide.md) — guía manual EasyPanel
7. [`.github/workflows/build-optimia-chatwoot-staging.yml`](../../.github/workflows/build-optimia-chatwoot-staging.yml) — workflow build staging (manual)

## Producción verificada (Sprint 1 — no modificar)

| Servicio EasyPanel | Imagen |
|--------------------|--------|
| `chatwoot` | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| `chatwoot-sidekiq` | Misma imagen |
| `chatwoot-db` | PostgreSQL dedicado prod |
| `chatwoot-redis` | Redis dedicado prod |
