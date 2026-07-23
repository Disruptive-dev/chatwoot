# Controles de aislamiento — Staging vs Producción

> Checklist obligatorio antes de crear, configurar o iniciar cualquier servicio staging.

## Clasificación de recursos

| Recurso | Producción (NO TOCAR) | Staging (NUEVO) |
|---------|----------------------|-----------------|
| Proyecto EasyPanel | Existente | Proyecto separado |
| Web | `chatwoot` | `chatwoot-staging` |
| Worker | `chatwoot-sidekiq` | `chatwoot-staging-sidekiq` |
| PostgreSQL | `chatwoot-db` | `chatwoot-staging-db` |
| Redis | `chatwoot-redis` | `chatwoot-staging-redis` |
| Storage | Volumen/bucket prod | Volumen/bucket staging |
| Dominio | `app.optimia.spectra-metrics.com` | `staging.optimia.spectra-metrics.com` |
| Imagen tag | `v4.10.1-optimia.6` | `staging-cw-*` |

---

## Checklist pre-creación (EasyPanel)

Marcar **antes** de crear el proyecto staging:

- [ ] Confirmé que estoy en EasyPanel con permisos de admin.
- [ ] Crearé un **proyecto nuevo**, no editaré el proyecto prod.
- [ ] No copiaré variables ENV desde prod (ni capturas con valores visibles).
- [ ] No restauraré dump de `chatwoot-db` en staging.
- [ ] No montaré volúmenes del proyecto prod.
- [ ] Dominio staging distinto del prod.

---

## Checklist pre-ENV (variables)

- [ ] `SECRET_KEY_BASE` generado nuevo (no igual a prod).
- [ ] `POSTGRES_HOST` = hostname staging (`chatwoot-staging-db`).
- [ ] `POSTGRES_PASSWORD` generado nuevo.
- [ ] `REDIS_URL` apunta a `chatwoot-staging-redis`.
- [ ] `REDIS_PASSWORD` generado nuevo.
- [ ] `FRONTEND_URL` = URL staging (no `app.optimia.spectra-metrics.com`).
- [ ] Sin `DATABASE_URL` heredada de prod.
- [ ] Tokens Spectra (si usados) son de entorno staging.
- [ ] SMTP vacío o sandbox (no credenciales prod).

### Verificación rápida de hostnames

```text
PROHIBIDO en staging:
  chatwoot-db
  chatwoot-redis
  postgres (si es alias prod en mismo proyecto)

PERMITIDO en staging:
  chatwoot-staging-db
  chatwoot-staging-redis
```

---

## Checklist pre-imagen

- [ ] Tag staging tiene prefijo `staging-`.
- [ ] Tag prod `v4.10.1-optimia.6` no fue sobrescrito en GHCR.
- [ ] Web y worker staging usan el **mismo** tag staging.
- [ ] Workflow prod (`build-optimia-chatwoot.yml`) no fue modificado.

---

## Checklist pre-migraciones

- [ ] Migraciones se ejecutan contra `chatwoot_staging` (BD vacía).
- [ ] `POSTGRES_HOST` en el job = `chatwoot-staging-db`.
- [ ] No hay conectividad de red desde job de migración hacia `chatwoot-db`.

---

## Checklist pre-arranque web/worker

- [ ] BD staging responde (`pg_isready`).
- [ ] Redis staging responde (`PING`).
- [ ] Migraciones completadas (`db:chatwoot_prepare` OK).
- [ ] Worker iniciado **después** de web (o en paralelo tras migraciones).
- [ ] Healthcheck `/health` configurado.

---

## Integraciones — prohibiciones en staging

| Integración | Staging |
|-------------|---------|
| WhatsApp Cloud / Evolution | **No conectar** |
| Facebook / Instagram | **No conectar** |
| Webhooks a sistemas prod | **No configurar** |
| Spectra Flow prod | **No usar** — solo endpoint staging |
| SMTP prod | **No usar** |
| S3/R2 bucket prod | **No usar** — volumen local o bucket staging |

---

## Señales de alarma (detener inmediatamente)

| Señal | Acción |
|-------|--------|
| Login muestra conversaciones de clientes reales | **Parar** — BD prod conectada por error |
| `FRONTEND_URL` redirige a prod | Revisar ENV y rebuild imagen staging |
| Mensajes WhatsApp salen a clientes reales | **Parar** — canal real conectado |
| Webhooks llegan a sistemas prod | Deshabilitar webhooks en cuenta staging |
| Logs muestran `chatwoot-db` como host | Corregir ENV antes de continuar |

---

## Matriz de riesgo

| Error | Impacto | Probabilidad | Mitigación |
|-------|---------|--------------|------------|
| Mismo `POSTGRES_HOST` que prod | **Crítico** — corrupción/exposición datos | Media | Checklist ENV + nombres distintos |
| Mismo Redis | Alto — jobs cruzados | Media | Hostname distinto |
| Mismo `SECRET_KEY_BASE` | Alto — cookies compartidas | Baja | Generar siempre nuevo |
| Tag imagen prod en staging | Medio — URLs baked incorrectas | Media | Prefijo `staging-` |
| Dump prod en staging | **Crítico** — datos PII en staging | Baja | Prohibir explícitamente |

---

## Responsable

Antes de cada deploy staging, una persona debe firmar (mentalmente o en ticket):

> Confirmé los 4 checklists (pre-creación, pre-ENV, pre-imagen, pre-migraciones) y ningún recurso apunta a producción.

---

## Referencias

- Arquitectura: [`staging-architecture.md`](staging-architecture.md)
- Variables: [`staging-variables.md`](staging-variables.md)
- Guía EasyPanel: [`../operations/easypanel-staging-setup-guide.md`](../operations/easypanel-staging-setup-guide.md)
