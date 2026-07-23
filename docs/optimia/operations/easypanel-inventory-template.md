# Plantilla de inventario EasyPanel — OptimiA

> Completar **manualmente** en el panel EasyPanel. **No incluir valores secretos.**

Fecha de inventario: _______________  
Responsable: _______________

---

## Proyecto EasyPanel

| Campo | Valor |
|-------|-------|
| Nombre del proyecto | |
| Dominio principal | |
| Ambiente (prod/staging) | |
| Fecha último deploy | |
| Responsable del deploy | |

---

## Servicio Web

| Campo | Valor |
|-------|-------|
| Nombre del servicio | |
| Origen del deploy (GitHub / imagen / compose) | |
| Repositorio (si aplica) | |
| Imagen Docker (si aplica) | |
| **Tag exacto** | |
| Commit SHA desplegado (si disponible) | |
| Comando de inicio | |
| Puerto expuesto | |
| Healthcheck configurado | |
| URL healthcheck | |
| Volúmenes montados | |
| Política de restart | |
| Réplicas | |

### Verificación web

- [ ] `GET /health` responde 200
- [ ] Login funcional
- [ ] Dashboard carga

---

## Servicio Worker

| Campo | Valor |
|-------|-------|
| **¿Existe worker?** | ☐ Sí  ☐ No |
| Nombre del servicio | |
| Imagen Docker | |
| **Tag exacto** | |
| Comando de inicio | |
| ¿Misma imagen que web? | ☐ Sí  ☐ No |
| Acceso a PostgreSQL | ☐ Sí  ☐ No |
| Acceso a Redis | ☐ Sí  ☐ No |
| Volúmenes montados | |
| Política de restart | |

### Verificación worker

- [ ] Proceso Sidekiq activo
- [ ] Jobs se procesan (enviar email de prueba)
- [ ] Queue latency aceptable

---

## PostgreSQL

| Campo | Valor |
|-------|-------|
| Nombre del servicio | |
| Versión | |
| Volumen / persistencia | |
| Estrategia de backup | |
| Frecuencia de backup | |
| Última prueba de restauración | |
| Fecha última prueba | |
| Tamaño actual (aprox.) | |

---

## Redis

| Campo | Valor |
|-------|-------|
| Nombre del servicio | |
| Versión | |
| Autenticación habilitada (`requirepass`) | ☐ Sí  ☐ No |
| Volumen / persistencia | |
| Uso Sidekiq confirmado | ☐ Sí  ☐ No |
| Uso ActionCable confirmado | ☐ Sí  ☐ No |

---

## Active Storage

| Campo | Valor |
|-------|-------|
| Tipo | ☐ Local  ☐ S3  ☐ R2  ☐ GCS  ☐ Azure |
| Volumen local (ruta) | |
| Bucket (si cloud) | |
| Región | |
| Persistencia confirmada | ☐ Sí  ☐ No |
| Backup configurado | ☐ Sí  ☐ No |
| Política de retención | |

---

## Variables de entorno

Registrar **solo nombres**. Marcar clasificación.

### Obligatorias

| Variable | Web | Worker | Sensible | Presente |
|----------|-----|--------|----------|----------|
| `SECRET_KEY_BASE` | ☐ | ☐ | ☐ | ☐ |
| `FRONTEND_URL` | ☐ | ☐ | ☐ | ☐ |
| `POSTGRES_HOST` | ☐ | ☐ | ☐ | ☐ |
| `POSTGRES_USERNAME` | ☐ | ☐ | ☐ | ☐ |
| `POSTGRES_PASSWORD` | ☐ | ☐ | ☐ | ☐ |
| `REDIS_URL` | ☐ | ☐ | ☐ | ☐ |
| `REDIS_PASSWORD` | ☐ | ☐ | ☐ | ☐ |
| `RAILS_ENV` | ☐ | ☐ | ☐ | ☐ |

### Recomendadas

| Variable | Web | Worker | Sensible | Presente |
|----------|-----|--------|----------|----------|
| `FORCE_SSL` | ☐ | ☐ | ☐ | ☐ |
| `ENABLE_RACK_ATTACK` | ☐ | ☐ | ☐ | ☐ |
| `ACTIVE_STORAGE_SERVICE` | ☐ | ☐ | ☐ | ☐ |
| `RAILS_LOG_TO_STDOUT` | ☐ | ☐ | ☐ | ☐ |
| `INSTALLATION_NAME` | ☐ | ☐ | ☐ | ☐ |
| `BRAND_NAME` | ☐ | ☐ | ☐ | ☐ |

### Spectra Flow

| Variable | Web | Worker | Sensible | Presente |
|----------|-----|--------|----------|----------|
| `SPECTRA_FLOW_API_URL` | ☐ | ☐ | ☐ | ☐ |
| `SPECTRA_FLOW_API_TOKEN` | ☐ | ☐ | ☐ | ☐ |
| `SPECTRA_FLOW_INBOX_BEARER_TOKEN` | ☐ | ☐ | ☐ | ☐ |

### Opcionales

| Variable | Web | Worker | Sensible | Presente |
|----------|-----|--------|----------|----------|
| `SENTRY_DSN` | ☐ | ☐ | ☐ | ☐ |
| `S3_BUCKET_NAME` | ☐ | ☐ | ☐ | ☐ |
| `AWS_ACCESS_KEY_ID` | ☐ | ☐ | ☐ | ☐ |
| `AWS_SECRET_ACCESS_KEY` | ☐ | ☐ | ☐ | ☐ |
| `SMTP_ADDRESS` | ☐ | ☐ | ☐ | ☐ |
| `OPENAI_API_KEY` | ☐ | ☐ | ☐ | ☐ |

---

## Cadena de trazabilidad

Completar cada eslabón. Marcar ☐ OK o ☐ RUPTURA.

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Repositorio auditado                                     │
│    org/repo: ________________________________               │
│    rama: ____________  commit: ____________                 │
│    Estado: ☐ OK  ☐ RUPTURA                                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. Workflow GitHub Actions                                  │
│    workflow: build-optimia-chatwoot.yml                     │
│    último run exitoso: ____________                         │
│    commit del run: ____________                             │
│    Estado: ☐ OK  ☐ RUPTURA                                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. Imagen GHCR generada                                     │
│    registry: ghcr.io/____________/____________              │
│    tag: ________________________________                    │
│    digest (sha256): ________________________________        │
│    Estado: ☐ OK  ☐ RUPTURA                                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. Tag utilizado en EasyPanel                               │
│    imagen:tag en servicio web: ____________________________ │
│    imagen:tag en servicio worker: _________________________ │
│    ¿Coincide con GHCR? ☐ Sí  ☐ No                          │
│    Estado: ☐ OK  ☐ RUPTURA                                 │
└──────────────────────────┬──────────────────────────────────┘
                           ▼
┌─────────────────────────────────────────────────────────────┐
│ 5. Commit efectivamente desplegado                          │
│    SHA verificado (si disponible): ________________________ │
│    ¿Coincide con repo? ☐ Sí  ☐ No  ☐ No verificable       │
│    Estado: ☐ OK  ☐ RUPTURA                                 │
└─────────────────────────────────────────────────────────────┘
```

### Valores de referencia (Sprint 0 — repositorio)

| Eslabón | Valor conocido |
|---------|----------------|
| Repo auditado | `pablo-paez-dev/chatwoot` @ `develop` / `462802c9e` |
| Workflow | `build-optimia-chatwoot.yml` — último run 2026-07-16 exitoso |
| Imagen GHCR esperada | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Tag EasyPanel | **Pendiente verificación manual** |
| Commit desplegado | **Pendiente verificación manual** |

### Rupturas detectadas (completar)

| # | Eslabón | Descripción de la ruptura |
|---|---------|---------------------------|
| 1 | | |
| 2 | | |
| 3 | | |

---

## Notas adicionales

_Espacio libre para observaciones del inventario._
