# Facebook Comments — OptimiA Integration

## AUDIT_RESULT

| Área | Hallazgo |
|------|----------|
| Webhooks actuales | `/bot` (Messenger), `/webhooks/instagram`, `/webhooks/whatsapp` |
| Feed/comments | **No existían** antes de este PR |
| OptimiA en Facebook | Hotfix Messenger + diagnósticos; sin pipeline de comentarios |
| Lead Hub | **No existía**; se agrega `optimia_facebook_comment_leads` |
| Idempotencia Messenger | Mutex Redis; comentarios usan `idempotency_key` en BD |
| Graph API version | `FACEBOOK_API_VERSION` default `v18.0` |

## CURRENT_CAPABILITY (antes)

- Messenger DM receive/reply
- Instagram DM via Page
- Sin comentarios de publicaciones
- Sin property context
- Sin Lead Hub para Facebook comments

## MISSING_COMPONENTS (implementados en este PR)

- Webhook `GET/POST /webhooks/facebook` para object `page` + field `feed`
- Pipeline OptimiA tenant-scoped con feature flags
- Idempotencia y estados de evento
- Property mapping `optimia_facebook_post_properties`
- Lead Hub `optimia_facebook_comment_leads`
- Public/private reply via Graph API
- Handoff con pausa de automatización
- Observabilidad estructurada

## META_REQUIREMENTS

| Requisito | Valor |
|-----------|-------|
| Webhook object | `page` |
| App-level subscription | `feed` (Meta App Dashboard → Webhooks → Page) |
| Page-level subscription | `POST /{page-id}/subscribed_apps?subscribed_fields=feed` |
| Callback URL | `https://<host>/webhooks/facebook` |
| Verify token | `FB_VERIFY_TOKEN` |
| Signature | `X-Hub-Signature-256` con `FB_APP_SECRET` |
| Page access token | Requerido (almacenado en `channel_facebook_pages`) |
| Permisos OAuth | `pages_manage_metadata`, `pages_show_list`, `pages_read_engagement`, `pages_read_user_content`, `pages_manage_engagement`, `pages_messaging` (private reply) |
| App Review | Requerido para permisos avanzados en modo Live |
| Advanced Access | `pages_manage_engagement`, `pages_read_user_content` típicamente requieren revisión |
| Graph API endpoints | `POST /{comment-id}/comments`, `POST /{comment-id}/private_replies`, `POST /{page-id}/subscribed_apps` |
| API version | `FACEBOOK_API_VERSION` (default `v18.0`) |

### Configuración manual obligatoria en Meta Developers

1. Webhooks → Page → suscribir campo `feed` a nivel app
2. Callback URL: `/webhooks/facebook`
3. Reautorizar Page con nuevos scopes (`pages_manage_engagement`, `pages_read_user_content`)
4. Suscribir Page al app con `feed` (rake `optimia:facebook_comments:activate[ACCOUNT_ID]` o API)
5. Verificar permisos concedidos en Access Token Debugger

## FEATURE_FLAGS (default: false, vía `account.custom_attributes`)

| Key | Descripción |
|-----|-------------|
| `optimia_facebook_comments_enabled` | Master switch por tenant |
| `optimia_facebook_comment_ai_reply_enabled` | Respuestas AI públicas |
| `optimia_facebook_comment_private_reply_enabled` | Private reply / Messenger continuation |

> Nota: `config/features.yml` alcanzó el límite de bit flags (64). Estos flags usan `custom_attributes` del account.

Activación Javier Paz (ejemplo):

```bash
bundle exec rake optimia:facebook_comments:activate[ACCOUNT_ID]
```

Mapear publicaciones:

```ruby
OptimiaFacebookPostProperty.create!(
  account: account,
  page_id: 'PAGE_ID',
  post_id: 'POST_ID',
  property_id: 'PROPERTY_ID',
  source: 'manual',
  known_facts: { 'price' => '...', 'location' => '...', 'availability' => '...' }
)
```

## DEPLOY_PLAN

1. Merge PR → build imagen staging
2. Migración BD: `optimia_facebook_comment_*` tables
3. Configurar webhook `feed` en Meta App (staging primero)
4. Activar flags solo para cuenta Javier Paz
5. Smoke test con comentario real en staging
6. Promover a prod tras validación

## ACTIVATION_PLAN

1. Confirmar `account_id` de Javier Paz en producción
2. Ejecutar rake activate con account_id
3. Cargar mappings post_id → property_id con `known_facts` oficiales
4. Verificar en logs: `COMMENT_RECEIVED` → `PUBLIC_REPLY_SENT`
5. Validar cero respuestas duplicadas en retry webhook

## ROLLBACK_PLAN

1. `Integrations::Optimia::FacebookComments::Feature.disable_for_account!(account)`
2. Desuscribir `feed` en Page (`DELETE /{page-id}/subscribed_apps`)
3. Revert deploy si necesario (tablas nuevas son aditivas)
