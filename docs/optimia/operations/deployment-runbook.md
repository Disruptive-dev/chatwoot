# Runbook: Deployment — OptimiA

> Diseño del flujo de despliegue objetivo. **No ejecutar en producción en Sprint 0.**

## Flujo estándar

```
commit
  → lint + test (CI)
  → build imagen Docker
  → push a GHCR (tag inmutable)
  → deploy staging (mismo tag)
  → smoke tests
  → promoción del mismo tag
  → deploy producción
  → validación post-deploy
```

## 1. Pre-requisitos

- [ ] PR aprobado y mergeado a `develop` o `main`
- [ ] CI verde (lint, tests, build)
- [ ] Tag de imagen generado: `cw-X.Y.Z-optimia-A.B.C`
- [ ] Backup reciente de PostgreSQL y storage
- [ ] Inventario EasyPanel actualizado
- [ ] Changelog documentado

## 2. Build y publicación

### 2.1 Trigger CI

Push a `develop` dispara `build-optimia-chatwoot.yml` (estado actual).

**Objetivo futuro:** workflow en `DSW-Factory/optimia-chatwoot` publicando a `ghcr.io/dsw-factory/optimia-chatwoot`.

### 2.2 Tag inmutable

```
ghcr.io/dsw-factory/optimia-chatwoot:cw-4.10.1-optimia-0.1.3
```

Registrar:
- Tag
- Digest SHA256
- Commit source
- Fecha/hora build

### 2.3 Verificación post-build

```bash
# Conceptual — verificar imagen existe
docker pull ghcr.io/dsw-factory/optimia-chatwoot:<tag>
docker inspect ghcr.io/dsw-factory/optimia-chatwoot:<tag> --format='{{.Id}}'
```

## 3. Release job — migraciones

**Antes** de actualizar web y worker:

```bash
docker run --rm \
  --env-file /path/to/production.env \
  ghcr.io/dsw-factory/optimia-chatwoot:<tag> \
  sh -c 'POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare'
```

Verificar:
- [ ] Migraciones aplicadas sin error
- [ ] No hay migraciones pendientes: `rails db:migrate:status`

## 4. Deploy staging

### 4.1 Actualizar servicios

1. Actualizar tag en servicio **web** de staging.
2. Actualizar tag en servicio **worker** de staging (mismo tag).
3. Restart servicios.

### 4.2 Smoke tests staging

| Test | Comando / acción | Esperado |
|------|------------------|----------|
| Health | `curl -f https://staging.../health` | `{"status":"woot"}` |
| Login | Login con cuenta de prueba | Dashboard carga |
| Inbox | Abrir conversación | Mensajes visibles |
| Worker | Enviar email de prueba | Email recibido |
| Spectra | `@documentos` en reply box | Modal abre (si configurado) |
| Adjuntos | Descargar adjunto existente | Archivo OK |
| WebSocket | Recibir mensaje en tiempo real | Notificación live |

### 4.3 Criterio de promoción

- Todos los smoke tests pasan.
- Sin errores 5xx en logs durante 15 minutos.
- Sidekiq procesa jobs sin backlog creciente.

## 5. Promoción a producción

### 5.1 Principio clave

**Promover el mismo tag** desplegado en staging. No reconstruir.

### 5.2 Secuencia

1. Backup pre-deploy (ver [`backup-runbook.md`](backup-runbook.md)).
2. Ejecutar release job migraciones en prod (si no se hizo en staging con misma DB).
3. Actualizar tag worker en EasyPanel prod.
4. Actualizar tag web en EasyPanel prod.
5. Verificar healthcheck.
6. Monitorear logs 30 minutos.

### 5.3 Validación post-deploy

- [ ] `GET /health` → 200
- [ ] Login funcional
- [ ] Conversaciones activas accesibles
- [ ] Jobs Sidekiq procesando
- [ ] Sin spike de errores en Sentry
- [ ] Tag y digest documentados en inventario

## 6. Rollback

Si falla validación post-deploy, ejecutar [`rollback-runbook.md`](rollback-runbook.md).

## 7. Estado actual (Sprint 0) — gaps

| Gap | Impacto |
|-----|---------|
| Dockerfile solo web | Worker debe ser servicio separado manual |
| Sin release job automatizado | Migraciones manuales |
| Tag `:optimia-latest` en CI | Riesgo de deploy no reproducible |
| Sin staging documentado | Promoción directa a prod posible |
| Repo en cuenta personal | Sin governance de org |

## 8. Registro de deploy

| Campo | Valor |
|-------|-------|
| Fecha/hora | |
| Tag imagen | |
| Digest SHA256 | |
| Commit | |
| Ejecutor | |
| Migraciones aplicadas | ☐ Sí ☐ No |
| Smoke tests | ☐ Pass ☐ Fail |
| Rollback necesario | ☐ Sí ☐ No |
