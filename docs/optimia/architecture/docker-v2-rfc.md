# RFC: Docker v2 — OptimiA

| Campo | Valor |
|-------|-------|
| Estado | **PROPUESTA** — no implementada |
| Autor | Sprint 0 — OptimiA |
| Fecha | 2026-07-23 |
| Reemplaza | `Dockerfile` raíz actual |

## 1. Contexto

El `Dockerfile` actual en la raíz del repositorio:

- Es single-stage sobre `ruby:3.4.4-slim`.
- Solo ejecuta `rails server` (sin Sidekiq).
- Corre como **root**.
- No define `HEALTHCHECK`.
- No sigue el patrón multi-stage del `docker/Dockerfile` oficial.
- Bakea `FRONTEND_URL` y branding en build time.

## 2. Objetivos

1. Basarse en `docker/Dockerfile` oficial de Chatwoot (multi-stage Alpine).
2. Imagen **única** reutilizable para web y worker (comando por servicio).
3. Usuario **non-root**.
4. `HEALTHCHECK` en web.
5. Assets precompilados sin secretos reales en capas.
6. Tags inmutables en GHCR.
7. Compatible con EasyPanel (un servicio = un comando).
8. Migraciones como release job externo.
9. Soporte Active Storage local y S3/R2.

## 3. Diseño propuesto

### 3.1 Estructura multi-stage

```dockerfile
# Stage 1: pre-builder (node + ruby, compila assets y gems)
FROM ruby:3.4.4-alpine3.21 AS pre-builder
# ... (basado en docker/Dockerfile upstream)

# Stage 2: runtime (solo runtime deps + artefactos compilados)
FROM ruby:3.4.4-alpine3.21 AS runtime
# ... copiar /gems y /app desde pre-builder
```

### 3.2 Usuario non-root

```dockerfile
RUN addgroup -g 1000 optimia && adduser -D -u 1000 -G optimia optimia
USER optimia
WORKDIR /app
```

### 3.3 Build args (no secretos)

| ARG | Propósito | Default |
|-----|-----------|---------|
| `RAILS_ENV` | Entorno | `production` |
| `INSTALLATION_NAME` | Branding build-time | `OptimIA` |
| `BRAND_NAME` | Branding build-time | `OptimIA` |
| `FRONTEND_URL` | URL para asset helpers | *(requerido en build)* |

`SECRET_KEY_BASE` en build: usar placeholder fijo (`precompile_placeholder`), nunca secret real.

### 3.4 Imagen única, comandos por servicio

EasyPanel / compose define el comando, no el Dockerfile:

```yaml
# optimia-web
command: ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

# optimia-worker
command: ["bundle", "exec", "sidekiq", "-C", "config/sidekiq.yml"]
```

`ENTRYPOINT`: `docker/entrypoints/rails.sh` (espera Postgres, existente).

### 3.5 Healthcheck (web)

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1
```

### 3.6 Chequeo worker

No HEALTHCHECK en imagen para worker. EasyPanel puede usar:

```bash
pgrep -f sidekiq
```

O monitor externo de queue latency.

### 3.7 Migraciones (release job)

**No** incluir en CMD/ENTRYPOINT. Job separado en CI/CD:

```bash
docker run --rm \
  -e POSTGRES_HOST=... -e REDIS_URL=... \
  ghcr.io/dsw-factory/optimia-chatwoot:<tag> \
  bundle exec rails db:chatwoot_prepare
```

Ejecutar **antes** de actualizar web y worker.

### 3.8 Active Storage

| Modo | Configuración |
|------|---------------|
| Local | Volumen `/app/storage` montado en web y worker |
| S3/R2 | `ACTIVE_STORAGE_SERVICE=s3_compatible` + credenciales ENV en runtime |

La imagen no contiene credenciales de storage.

### 3.9 Tags inmutables

```
ghcr.io/dsw-factory/optimia-chatwoot:cw-4.10.1-optimia-0.1.2
```

Prohibido `:latest` en producción.

### 3.10 Rollback

1. Re-deploy tag anterior en web y worker.
2. Si migraciones fueron compatibles hacia adelante: no requiere rollback DB.
3. Si migraciones incompatibles: restaurar backup PostgreSQL (ver rollback-runbook).

## 4. Compatibilidad EasyPanel

| Requisito EasyPanel | Cumplimiento propuesto |
|---------------------|------------------------|
| Imagen desde GHCR | Sí |
| Puerto 3000 | Sí (web) |
| Healthcheck HTTP | Sí (`/health`) |
| Servicio worker separado | Sí (misma imagen, distinto comando) |
| Variables ENV | Runtime, no baked |
| Volúmenes storage | Montaje externo |

## 5. Plan de implementación (futuro)

1. Crear `docker/Dockerfile.optimia` basado en `docker/Dockerfile`.
2. Actualizar `build-optimia-chatwoot.yml` para usar nuevo Dockerfile.
3. Probar build local sin push.
4. Desplegar en staging con web + worker.
5. Smoke tests completos.
6. Deprecar `Dockerfile` raíz (mover a `docker/Dockerfile.optimia.legacy`).

## 6. No incluido en esta RFC

- Cambios de branding funcional.
- Integración Evolution API.
- Upgrade de Chatwoot base.

## 7. Decisión

**Pendiente de aprobación** tras completar inventario EasyPanel y validar staging.
