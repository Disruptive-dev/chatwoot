# Configuración web y worker — Staging OptimiA

> Especificación para EasyPanel. Espejo de producción verificada, con nombres y tags staging.

## Producción de referencia (no modificar)

| Servicio | Comando típico | Imagen |
|----------|----------------|--------|
| `chatwoot` | `bundle exec rails server -b 0.0.0.0 -p 3000` | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| `chatwoot-sidekiq` | `bundle exec sidekiq -C config/sidekiq.yml` | Misma imagen |

---

## chatwoot-staging (web)

| Campo | Valor |
|-------|-------|
| **Tipo** | Docker image |
| **Imagen** | `ghcr.io/disruptive-dev/chatwoot` |
| **Tag** | `staging-cw-4.10.1-optimia-0.1.2` *(tras build staging)* |
| **Comando** | `bundle exec rails server -b 0.0.0.0 -p 3000` |
| **Puerto interno** | `3000` |
| **Puerto público** | Asignado por EasyPanel (proxy HTTPS) |
| **Restart** | `always` |
| **Healthcheck** | `GET /health` → `{"status":"woot"}` |

### Healthcheck EasyPanel

```
Path: /health
Interval: 30s
Timeout: 10s
Start period: 90s
```

### Volúmenes

| Montaje | Ruta contenedor | Propósito |
|---------|-----------------|-----------|
| `chatwoot-staging-storage` | `/app/storage` | Active Storage local |

### Dependencias (orden de arranque)

1. `chatwoot-staging-db` — running
2. `chatwoot-staging-redis` — running
3. Release job migraciones (una vez)
4. `chatwoot-staging` — web
5. `chatwoot-staging-sidekiq` — worker

### Variables ENV

Ver [`staging-variables.md`](staging-variables.md). **Idénticas** en web y worker (excepto `PORT` / `RAILS_MAX_THREADS` solo web).

---

## chatwoot-staging-sidekiq (worker)

| Campo | Valor |
|-------|-------|
| **Tipo** | Docker image |
| **Imagen** | `ghcr.io/disruptive-dev/chatwoot` |
| **Tag** | **Idéntico al web** |
| **Comando** | `bundle exec sidekiq -C config/sidekiq.yml` |
| **Puerto** | Ninguno expuesto |
| **Restart** | `always` |

### Volúmenes

| Montaje | Ruta contenedor |
|---------|-----------------|
| `chatwoot-staging-storage` | `/app/storage` |

> Compartir el **mismo volumen** que web si `ACTIVE_STORAGE_SERVICE=local`.

### Verificación operativa

| Test | Cómo verificar |
|------|----------------|
| Proceso activo | Logs: `Sidekiq starting` |
| Jobs procesan | Crear conversación de prueba → email/job en logs |
| Redis conectado | Sin `Redis::CannotConnectError` en logs |

---

## Release job — migraciones (antes del primer arranque)

Ejecutar **una vez** sobre BD staging vacía (contenedor one-shot o consola EasyPanel):

```bash
POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
```

Usar la **misma imagen y ENV** que web/worker.

**No ejecutar** contra `chatwoot-db` (producción).

---

## chatwoot-staging-db

| Campo | Valor recomendado |
|-------|-------------------|
| **Imagen** | `pgvector/pgvector:pg16` |
| **Variables** | `POSTGRES_DB=chatwoot_staging`, `POSTGRES_USER=chatwoot_staging`, `POSTGRES_PASSWORD=<nuevo>` |
| **Volumen** | Persistente, dedicado staging |
| **Puerto** | `5432` (interno) |

---

## chatwoot-staging-redis

| Campo | Valor recomendado |
|-------|-------------------|
| **Imagen** | `redis:alpine` |
| **Comando** | `redis-server --requirepass <password-nuevo>` |
| **Volumen** | Opcional (staging puede tolerar pérdida de cola) |

---

## Smoke tests post-configuración

| # | Test | Esperado |
|---|------|----------|
| 1 | `curl -f https://staging.../health` | 200 + `woot` |
| 2 | Login super admin (cuenta creada en seed) | Dashboard carga |
| 3 | Crear inbox de prueba (API/website) | Sin error |
| 4 | Enviar mensaje de prueba | Visible en UI |
| 5 | Verificar worker | Job completado en logs |
| 6 | `@documentos` (si Spectra staging configurado) | Modal o error controlado `spectra_not_configured` |

---

## Diferencias intencionales vs producción

| Aspecto | Producción | Staging |
|---------|------------|---------|
| Nombre servicios | `chatwoot*` | `chatwoot-staging*` |
| Tag imagen | `v4.10.1-optimia.6` | `staging-cw-4.10.1-optimia-0.1.2` |
| `FRONTEND_URL` | `app.optimia.spectra-metrics.com` | `staging.optimia.spectra-metrics.com` |
| Datos | Clientes reales | Vacío + seed mínimo |
| Canales externos | Conectados | Deshabilitados |
