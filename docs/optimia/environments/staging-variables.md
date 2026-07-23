# Variables de entorno — Staging OptimiA

> Plantilla para configurar staging en EasyPanel. **Generar valores nuevos** — no copiar de producción.

Ver inventario completo: [`../inventory/environment-variables.md`](../inventory/environment-variables.md)

## Reglas

1. **Nunca** reutilizar `SECRET_KEY_BASE`, passwords de BD/Redis, ni tokens de prod.
2. **Nunca** apuntar `POSTGRES_HOST` o `REDIS_URL` a servicios prod (`chatwoot-db`, `chatwoot-redis`).
3. Hostnames internos EasyPanel: usar nombres del **proyecto staging** (`chatwoot-staging-db`, etc.).

---

## Obligatorias (web + worker)

| Variable | Valor staging (ejemplo seguro) | Notas |
|----------|------------------------------|-------|
| `RAILS_ENV` | `production` | Chatwoot usa `production` en contenedores |
| `NODE_ENV` | `production` | |
| `INSTALLATION_ENV` | `docker` | |
| `SECRET_KEY_BASE` | *(generar nuevo — 64+ chars hex)* | `rails secret` o `openssl rand -hex 64` |
| `FRONTEND_URL` | `https://staging.optimia.spectra-metrics.com` | **Distinto de prod** |
| `POSTGRES_HOST` | `chatwoot-staging-db` | Host interno EasyPanel staging |
| `POSTGRES_USERNAME` | `chatwoot_staging` | Nuevo usuario |
| `POSTGRES_PASSWORD` | *(generar nuevo)* | |
| `POSTGRES_DATABASE` | `chatwoot_staging` | BD vacía nueva |
| `REDIS_URL` | `redis://:PASSWORD@chatwoot-staging-redis:6379` | Password nuevo |
| `REDIS_PASSWORD` | *(generar nuevo)* | |

---

## Recomendadas (aislamiento y operación)

| Variable | Valor staging | Motivo |
|----------|---------------|--------|
| `FORCE_SSL` | `true` | Si TLS en EasyPanel |
| `RAILS_LOG_TO_STDOUT` | `true` | Logs contenedor |
| `LOG_LEVEL` | `debug` | Más verbose en staging |
| `ENABLE_ACCOUNT_SIGNUP` | `true` | Facilita pruebas (evaluar política) |
| `ENABLE_RACK_ATTACK` | `true` | |
| `ACTIVE_STORAGE_SERVICE` | `local` | Volumen `/app/storage` staging |
| `INSTALLATION_NAME` | `OptimIA Staging` | Distinguir en UI |
| `BRAND_NAME` | `OptimIA` | |
| `DEFAULT_LOCALE` | `es` | |

---

## Deshabilitar / vaciar (evitar conexión real)

| Variable | Valor staging | Motivo |
|----------|---------------|--------|
| `FB_APP_ID` | *(vacío)* | No Facebook real |
| `FB_APP_SECRET` | *(vacío)* | |
| `IG_VERIFY_TOKEN` | *(vacío)* | |
| `WHATSAPP_*` | *(vacío)* | No WhatsApp real |
| `TWITTER_*` | *(vacío)* | |
| `SLACK_CLIENT_ID` | *(vacío)* | |
| `GOOGLE_OAUTH_CLIENT_ID` | *(vacío)* o OAuth dev separado | |
| `STRIPE_SECRET_KEY` | *(vacío)* | |
| `OPENAI_API_KEY` | *(vacío)* o key dev separada | |

---

## Spectra Flow (staging)

Si se prueba integración documental en staging:

| Variable | Valor | Notas |
|----------|-------|-------|
| `SPECTRA_FLOW_API_URL` | URL API Spectra **staging** | No usar URL prod |
| `SPECTRA_FLOW_API_TOKEN` | Token **staging** nuevo | No copiar token prod |

Alternativa: dejar vacío y configurar solo vía `custom_attributes` de cuenta de prueba.

---

## SMTP (staging)

| Opción | Configuración |
|--------|---------------|
| A — Deshabilitado | `SMTP_ADDRESS` vacío (emails no salen) |
| B — Mailhog/sandbox | Host interno de prueba, sin destinatarios reales |
| C — Brevo/Sendgrid sandbox | API key **staging** separada |

**No usar** credenciales SMTP de producción.

---

## Solo web

| Variable | Valor |
|----------|-------|
| `PORT` | `3000` |
| `RAILS_MAX_THREADS` | `5` |

---

## Solo worker

| Variable | Valor |
|----------|-------|
| `SIDEKIQ_CONCURRENCY` | `5` (menor que prod si se desea) |

---

## Validación anti-producción

Antes de iniciar servicios, verificar:

```text
☐ FRONTEND_URL NO contiene app.optimia.spectra-metrics.com (prod)
☐ POSTGRES_HOST NO es chatwoot-db
☐ REDIS_URL NO apunta a chatwoot-redis
☐ SECRET_KEY_BASE ≠ valor prod (comparar longitud/formato, no el valor)
☐ Sin DATABASE_URL apuntando a prod
```

Ver checklist completo: [`staging-isolation-controls.md`](staging-isolation-controls.md)

---

## Plantilla `.env` staging (copiar a EasyPanel — rellenar valores nuevos)

```bash
# === STAGING ONLY — generar todos los secretos nuevos ===
RAILS_ENV=production
NODE_ENV=production
INSTALLATION_ENV=docker
SECRET_KEY_BASE=GENERAR_NUEVO
FRONTEND_URL=https://staging.optimia.spectra-metrics.com
INSTALLATION_NAME=OptimIA Staging
BRAND_NAME=OptimIA
FORCE_SSL=true
RAILS_LOG_TO_STDOUT=true
LOG_LEVEL=debug
ENABLE_ACCOUNT_SIGNUP=true
ENABLE_RACK_ATTACK=true
ACTIVE_STORAGE_SERVICE=local
DEFAULT_LOCALE=es
POSTGRES_HOST=chatwoot-staging-db
POSTGRES_USERNAME=chatwoot_staging
POSTGRES_PASSWORD=GENERAR_NUEVO
POSTGRES_DATABASE=chatwoot_staging
REDIS_PASSWORD=GENERAR_NUEVO
REDIS_URL=redis://:GENERAR_NUEVO@chatwoot-staging-redis:6379
# Spectra staging (opcional)
# SPECTRA_FLOW_API_URL=
# SPECTRA_FLOW_API_TOKEN=
```

**Mismas variables** en `chatwoot-staging` y `chatwoot-staging-sidekiq`.
