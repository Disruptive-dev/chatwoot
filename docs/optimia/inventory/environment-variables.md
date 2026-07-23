# Variables de entorno — OptimiA

> Inventario derivado de `.env.example`, Dockerfiles, workflows, inicializadores y código Spectra Flow.  
> **No contiene valores reales.**

## Leyenda

| Columna | Significado |
|---------|-------------|
| Req | R = Requerida, Rec = Recomendada, O = Opcional |
| Sens | S = Sensible (secreto) |
| Web | Requerida en servicio web |
| Worker | Requerida en servicio worker |
| .env.ex | Presente en `.env.example` |

---

## Core — Rails

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `SECRET_KEY_BASE` | Rails | R | S | `a1b2c3...64chars` | Integridad de cookies y sesiones | ✅ | ✅ | ✅ | Generar con `rails secret` |
| `FRONTEND_URL` | Rails | R | — | `https://app.example.com` | URL pública de la app | ✅ | ✅ | ✅ | Hardcodeado en CI actualmente |
| `HELPCENTER_URL` | Rails | O | — | `https://help.example.com` | URL del centro de ayuda | ✅ | ✅ | ✅ | |
| `RAILS_ENV` | Rails | R | — | `production` | Entorno Rails | ✅ | ✅ | ✅ | |
| `RAILS_LOG_TO_STDOUT` | Rails | Rec | — | `true` | Logs a stdout (contenedores) | ✅ | ✅ | ✅ | |
| `LOG_LEVEL` | Rails | O | — | `info` | Nivel de log | ✅ | ✅ | ✅ | |
| `FORCE_SSL` | Rails | Rec | — | `true` | Forzar HTTPS | ✅ | ✅ | ✅ | Obligatorio en prod |
| `RAILS_MAX_THREADS` | Rails | O | — | `5` | Hilos Puma | ✅ | ✅ | — | Solo web |
| `PORT` | Rails | O | — | `3000` | Puerto HTTP | — | ✅ | — | Heroku/EasyPanel |
| `NODE_ENV` | Assets | R | — | `production` | Entorno Node (build) | — | ✅ | — | En Dockerfile |
| `INSTALLATION_ENV` | Rails | Rec | — | `docker` | Tipo de instalación | — | ✅ | ✅ | Compose prod |
| `CW_API_ONLY_SERVER` | Rails | O | — | `false` | Solo API, sin UI | ✅ | ✅ | — | |
| `DEFAULT_LOCALE` | Rails | O | — | `es` | Idioma por defecto | ✅ | ✅ | ✅ | |

---

## PostgreSQL

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `POSTGRES_HOST` | DB | R | — | `postgres` | Host PostgreSQL | ✅ | ✅ | ✅ | |
| `POSTGRES_PORT` | DB | O | — | `5432` | Puerto | — | ✅ | ✅ | |
| `POSTGRES_USERNAME` | DB | R | — | `chatwoot_prod` | Usuario | ✅ | ✅ | ✅ | |
| `POSTGRES_PASSWORD` | DB | R | S | `***generado***` | Contraseña | ✅ | ✅ | ✅ | Sin default en prod |
| `POSTGRES_DATABASE` | DB | O | — | `chatwoot_production` | Nombre BD | ✅ | ✅ | ✅ | |
| `POSTGRES_STATEMENT_TIMEOUT` | DB | O | — | `600s` | Timeout queries | ✅ | ✅ | ✅ | Release job: 600s |
| `DATABASE_URL` | DB | O | S | `postgres://user:***@host/db` | URL completa | — | ✅ | ✅ | Alternativa a vars individuales |

---

## Redis

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `REDIS_URL` | Redis | R | S | `redis://:password@redis:6379` | URL Redis | ✅ | ✅ | ✅ | Incluye password |
| `REDIS_PASSWORD` | Redis | Rec | S | `***generado***` | Password Redis | ✅ | ✅ | ✅ | Docker compose |
| `REDIS_SENTINELS` | Redis | O | — | `host1:26379,host2:26379` | Sentinel hosts | ✅ | ✅ | ✅ | HA |
| `REDIS_SENTINEL_MASTER_NAME` | Redis | O | — | `mymaster` | Sentinel master | ✅ | ✅ | ✅ | |
| `REDIS_OPENSSL_VERIFY_MODE` | Redis | O | — | `none` | SSL verify | ✅ | ✅ | ✅ | Solo si necesario |

---

## Active Storage

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `ACTIVE_STORAGE_SERVICE` | Storage | R | — | `local` / `amazon` / `s3_compatible` | Backend storage | ✅ | ✅ | ✅ | R2 = s3_compatible |
| `S3_BUCKET_NAME` | S3 | O | — | `optimia-storage` | Bucket | ✅ | ✅ | ✅ | |
| `AWS_ACCESS_KEY_ID` | S3 | O | S | `AKIA...` | Access key | ✅ | ✅ | ✅ | |
| `AWS_SECRET_ACCESS_KEY` | S3 | O | S | `***` | Secret key | ✅ | ✅ | ✅ | |
| `AWS_REGION` | S3 | O | — | `us-east-1` | Región | ✅ | ✅ | ✅ | |
| `STORAGE_ACCESS_KEY_ID` | S3-compat | O | S | `***` | R2/Minio key | ✅ | ✅ | ✅ | |
| `STORAGE_SECRET_ACCESS_KEY` | S3-compat | O | S | `***` | R2/Minio secret | ✅ | ✅ | ✅ | |
| `STORAGE_BUCKET_NAME` | S3-compat | O | — | `optimia` | Bucket R2 | ✅ | ✅ | ✅ | |
| `STORAGE_ENDPOINT` | S3-compat | O | — | `https://xxx.r2.cloudflarestorage.com` | Endpoint | ✅ | ✅ | ✅ | |
| `STORAGE_REGION` | S3-compat | O | — | `auto` | Región | ✅ | ✅ | ✅ | |
| `DIRECT_UPLOADS_ENABLED` | Storage | O | — | `true` | Upload directo CDN | ✅ | ✅ | — | |

---

## Branding / OptimiA

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `INSTALLATION_NAME` | Branding | Rec | — | `OptimIA` | Nombre instalación | — | ✅ | ✅ | Build arg + runtime |
| `BRAND_NAME` | Branding | Rec | — | `OptimIA` | Nombre marca | — | ✅ | ✅ | Build arg + runtime |
| `ASSET_CDN_HOST` | Assets | O | — | `cdn.example.com` | CDN assets | ✅ | ✅ | — | |

---

## Spectra Flow (específicas OptimiA)

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `SPECTRA_FLOW_API_URL` | Spectra | O* | — | `https://flow-api.example.com` | URL base API Spectra | ❌ | ✅ | ✅ | *Requerida si Spectra activo |
| `SPECTRA_FLOW_API_TOKEN` | Spectra | O* | S | `***jwt***` | Bearer token global | ❌ | ✅ | ✅ | Fallback ENV |
| `SPECTRA_FLOW_INBOX_BEARER_TOKEN` | Spectra | O* | S | `***jwt***` | Token inbox global | ❌ | ✅ | ✅ | Prioridad sobre API_TOKEN |

### Custom attributes por cuenta (no ENV)

| Atributo | Componente | Sens | Descripción |
|----------|------------|------|-------------|
| `spectra_flow_api_url` | Account | — | URL API por cuenta (prioridad máxima) |
| `spectra_flow_bearer_token` | Account | S | Token por cuenta (prioridad máxima) |

Resolución: cuenta → GlobalConfig DB → ENV (ver `client.rb`).

---

## Channel Manager / Evolution API (OptimiA Sprint 2)

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `EVOLUTION_API_URL` | Evolution | O* | — | `https://evo-api.example.com` | URL base Evolution API | ❌ | ✅ | ✅ | *Req si Connection Center activo |
| `EVOLUTION_API_KEY` | Evolution | O* | S | `***` | API key global Evolution | ❌ | ✅ | ✅ | Solo server-side |
| `OPTIMIA_CHATWOOT_PUBLIC_URL` | Evolution→Chatwoot | O* | — | `https://app.example.com` | URL pública Chatwoot para Evolution | ❌ | ✅ | ✅ | Default: `FRONTEND_URL` |
| `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN` | Evolution→Chatwoot | O* | S | `***` | Token API Chatwoot para integración Evolution | ❌ | ✅ | ✅ | Fallback: token del admin |
| `OPTIMIA_CHANNEL_MANAGER_ENABLED` | Channel Manager | O | — | `true` | Kill switch global | ❌ | ✅ | ✅ | Default: `true` |
| `EVOLUTION_PAIRING_CODE_SUPPORTED` | Evolution | O | — | `false` | Habilita pairing code en UI | ❌ | ✅ | ✅ | Según soporte real Evolution |

Feature flag por cuenta: `optimia_channel_manager` (`config/features.yml`).

---

## Email / SMTP

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `MAILER_SENDER_EMAIL` | Email | Rec | — | `OptimIA <noreply@example.com>` | Remitente | ✅ | — | ✅ | Worker envía emails |
| `SMTP_ADDRESS` | SMTP | O | — | `smtp.example.com` | Host SMTP | ✅ | — | ✅ | |
| `SMTP_PORT` | SMTP | O | — | `587` | Puerto | ✅ | — | ✅ | |
| `SMTP_USERNAME` | SMTP | O | S | `user@example.com` | Usuario | ✅ | — | ✅ | |
| `SMTP_PASSWORD` | SMTP | O | S | `***` | Contraseña | ✅ | — | ✅ | |
| `SMTP_DOMAIN` | SMTP | O | — | `example.com` | Dominio HELO | ✅ | — | ✅ | |
| `SMTP_AUTHENTICATION` | SMTP | O | — | `plain` | Método auth | ✅ | — | ✅ | |
| `SMTP_ENABLE_STARTTLS_AUTO` | SMTP | O | — | `true` | STARTTLS | ✅ | — | ✅ | |

---

## Seguridad

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `ENABLE_RACK_ATTACK` | Security | Rec | — | `true` | Rate limiting | ✅ | ✅ | — | Solo web |
| `RACK_ATTACK_LIMIT` | Security | O | — | `3000` | Límite req/min | ✅ | ✅ | — | |
| `RACK_ATTACK_ALLOWED_IPS` | Security | O | — | `127.0.0.1` | IPs whitelist | ✅ | ✅ | — | |
| `ENABLE_ACCOUNT_SIGNUP` | Auth | Rec | — | `false` | Permitir registro | ✅ | ✅ | — | `false` en prod |
| `ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY` | MFA | O* | S | `***` | Cifrado AR | ✅ | ✅ | ✅ | *Req si MFA |
| `ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY` | MFA | O* | S | `***` | Cifrado AR | ✅ | ✅ | ✅ | |
| `ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT` | MFA | O* | S | `***` | Cifrado AR | ✅ | ✅ | ✅ | |

---

## Monitoreo

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `SENTRY_DSN` | Monitoring | O | S | `https://***@sentry.io/***` | Sentry backend | ✅ | ✅ | ✅ | |
| `SENTRY_FRONTEND_DSN` | Monitoring | O | S | `https://***@sentry.io/***` | Sentry frontend | — | ✅ | — | vueapp.html.erb |
| `LOGRAGE_ENABLED` | Logging | O | — | `true` | Log estructurado | ✅ | ✅ | ✅ | |

---

## Sidekiq / Worker

| Variable | Componente | Req | Sens | Ejemplo seguro | Descripción | .env.ex | Web | Worker | Observaciones |
|----------|------------|-----|------|----------------|-------------|---------|-----|--------|---------------|
| `SIDEKIQ_CONCURRENCY` | Sidekiq | O | — | `10` | Workers concurrentes | ✅ | — | ✅ | Solo worker |
| `ENABLE_SIDEKIQ_DEQUEUE_LOGGER` | Sidekiq | O | — | `false` | Log dequeue | ✅ | — | ✅ | |

---

## Build-time (Dockerfile / CI — no runtime secrets)

| Variable | Fuente | Sens | Ejemplo | Observaciones |
|----------|--------|------|---------|---------------|
| `SECRET_KEY_BASE` (build) | CI build-arg | — | `dummy_secret_key_base_for_assets` | Solo precompile |
| `FRONTEND_URL` (build) | CI build-arg | — | `https://app.optimia.spectra-metrics.com` | Baked en assets |
| `INSTALLATION_NAME` (build) | CI build-arg | — | `OptimIA` | |
| `BRAND_NAME` (build) | CI build-arg | — | `OptimIA` | |
| `NODE_OPTIONS` | Dockerfile ENV | — | `--max-old-space-size=4096` | Memoria Node build |

---

## Clasificación por servicio EasyPanel

### Compartidas (web + worker)

`SECRET_KEY_BASE`, `FRONTEND_URL`, `RAILS_ENV`, `POSTGRES_*`, `REDIS_*`, `ACTIVE_STORAGE_SERVICE`, `S3_*`, `STORAGE_*`, `SPECTRA_FLOW_*`, `INSTALLATION_NAME`, `BRAND_NAME`, `SENTRY_DSN`

### Exclusivas web

`PORT`, `RAILS_MAX_THREADS`, `ENABLE_RACK_ATTACK`, `SENTRY_FRONTEND_DSN`, `ASSET_CDN_HOST`

### Exclusivas worker

`SIDEKIQ_CONCURRENCY`, `SMTP_*`, `MAILER_SENDER_EMAIL`

---

## Variables ausentes en `.env.example` (agregar en sprint futuro)

- `SPECTRA_FLOW_API_URL`
- `SPECTRA_FLOW_API_TOKEN`
- `SPECTRA_FLOW_INBOX_BEARER_TOKEN`
- `INSTALLATION_NAME`
- `BRAND_NAME`
