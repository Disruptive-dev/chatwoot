# Deploy operativo — Facebook Messenger hotfix OptimiA 0.2.2

> Generado: 2026-07-29T15:13:17Z UTC  
> Sin secretos. Completar campos marcados `PENDIENTE` antes del deploy en EasyPanel.

## Resumen

| Campo | Valor |
|-------|-------|
| Versión OptimiA | **0.2.2** |
| Commit merge | `2374cdd24b83906908ae3e948cf8af5dd1775b3e` |
| PR | [#6](https://github.com/pablo-paez-dev/chatwoot/pull/6) (mergeado) |
| Tag Git | `optimia/v0.2.2` |
| Tag imagen (build) | `staging-cw-4.10.1-optimia-0.2.2` |
| Imagen nueva | `ghcr.io/pablo-paez-dev/chatwoot:staging-cw-4.10.1-optimia-0.2.2` |
| Digest nuevo | `sha256:cf5db37b14bf017a903677d2435ea8ecf5a8f9d5e7a2bbcdae9865cec352bb53` |
| Build workflow | [30463262179](https://github.com/pablo-paez-dev/chatwoot/actions/runs/30463262179) |
| Inbox Facebook prod | **46** |

## Causa confirmada

1. Envío saliente: `messaging_type: MESSAGE_TAG` + `tag: ACCOUNT_UPDATE` → Graph API `Invalid parameter`.
2. Perfil contacto: lookup PSID sin `fields` → error 100/subcode 33 → fallback "John Doe" (no bloquea recepción).

## Estado producción actual (pre-deploy)

| Campo | Valor |
|-------|-------|
| Imagen referencia | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Servicio web | `chatwoot` |
| Servicio worker | `chatwoot-sidekiq` |
| Dominio | `https://app.optimia.spectra-metrics.com` |
| Digest anterior (`OPTIMIA_ROLLBACK_DIGEST`) | **PENDIENTE** — copiar desde EasyPanel antes de cambiar imagen |

## Backup PostgreSQL (obligatorio antes de deploy)

```bash
# Ejecutar en host con acceso a chatwoot-db — PENDIENTE
pg_dump -h "$POSTGRES_HOST" -U "$POSTGRES_USERNAME" -d "$POSTGRES_DATABASE" \
  --format=custom --file="/backups/optimia-pg-pre-0.2.2-$(date +%Y%m%d-%H%M%S).dump"

pg_restore --list "/backups/optimia-pg-pre-0.2.2-*.dump" | head -20
```

**No restaurar ni modificar la base durante el hotfix.** Sin migraciones en este release.

## Diagnóstico Facebook (read-only, pre/post deploy)

```bash
bundle exec rake optimia:facebook:diagnose[46]
# Opcional con PSID conocido:
# bundle exec rake optimia:facebook:diagnose[46,<PSID>]
```

## Deploy EasyPanel (manual)

**Orden:** Sidekiq → verificar colas → Web → healthcheck → confirmar mismo digest en ambos.

1. Registrar `OPTIMIA_ROLLBACK_DIGEST` del digest actual en web y sidekiq.
2. Actualizar **chatwoot-sidekiq** a:
   ```
   ghcr.io/pablo-paez-dev/chatwoot@sha256:cf5db37b14bf017a903677d2435ea8ecf5a8f9d5e7a2bbcdae9865cec352bb53
   ```
3. Verificar Sidekiq running y consumiendo colas.
4. Actualizar **chatwoot** (web) al **mismo digest**.
5. Verificar `GET /health` → `{"status":"woot"}`.

**No modificar:** PostgreSQL, Redis, Evolution API, variables FB_*, Page Access Token, dominio, Traefik, webhook Meta.

## Rollback automático

Si falla cualquier componente crítico, revertir **web y sidekiq** a `OPTIMIA_ROLLBACK_DIGEST`:

```
ghcr.io/disruptive-dev/chatwoot@sha256:<OPTIMIA_ROLLBACK_DIGEST>
```

(o el digest/tag documentado en EasyPanel pre-deploy)

## Smoke tests post-deploy

| Check | Comando / acción | Resultado |
|-------|------------------|-----------|
| Health | `curl -f https://app.optimia.spectra-metrics.com/health` | PENDIENTE |
| Login | UI | PENDIENTE |
| Conversaciones | UI | PENDIENTE |
| Sidekiq | logs / cola | PENDIENTE |
| WhatsApp | envío/recepción | PENDIENTE |
| Evolution API | `curl https://evo-api.spectra-metrics.com` | OK pre-deploy (200) |
| Messenger entrante inbox 46 | mensaje desde Facebook | PENDIENTE |
| Messenger saliente inbox 46 | respuesta desde OptimiA | PENDIENTE |
| Logs envío | `facebook_message_send_succeeded`, sin `Invalid parameter` | PENDIENTE |
| Payload | `messaging_type: RESPONSE`, sin `ACCOUNT_UPDATE` | PENDIENTE |

## Tag producción formal (opcional)

Para publicar tag `cw-4.10.1-optimia-0.2.2` en GHCR:

GitHub Actions → **OptimiA Build Production** → inputs:

- `optimia_version`: `0.2.2`
- `chatwoot_version`: `4.10.1`
- `staging_digest`: `sha256:cf5db37b14bf017a903677d2435ea8ecf5a8f9d5e7a2bbcdae9865cec352bb53`
- `confirm_production`: `DEPLOY_OPTIMIA`

## Rotación posterior de credenciales (no durante hotfix)

- FB_APP_SECRET, FB_VERIFY_TOKEN, PostgreSQL password, Redis password, Spectra Flow bearer, webhook Flow secret.
