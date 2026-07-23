# Seguridad — Channel Manager

## Principios

1. **Credenciales Evolution solo server-side** (`EVOLUTION_API_URL`, `EVOLUTION_API_KEY`).
2. **Sin QR históricos en base de datos** — solo `qr_expires_at` y entrega efímera en API.
3. **Sin metadata técnica en respuestas públicas** — `public_attributes` filtra campos sensibles.
4. **Multi-tenant estricto** — todas las queries scoped por `account_id` + Pundit.
5. **Sin IDOR** — `policy_scope` + `find` dentro del account actual.

## Permisos

- Solo **administradores** de cuenta.
- Feature flag `optimia_channel_manager` requerido.
- Kill switch global `OPTIMIA_CHANNEL_MANAGER_ENABLED`.

## Datos en reposo

- `encrypted_credentials` usa `encrypts` de ActiveRecord cuando `Chatwoot.encryption_configured?`.
- No almacenar API key global de Evolution en el modelo.

## Auditoría

Tabla `optimia_channel_connection_audits` registra:

- `created`, `instance_provisioned`, `qr_generated`, `status_checked`
- `connected`, `provisioning_started`, `ready`
- `disconnected`, `reconnected`, `error`

Sin secretos en `metadata`.

## Exposición frontend

La UI nunca muestra:

- Nombres de instancia Evolution
- API keys
- URLs de webhooks
- Tokens Chatwoot

## Staging

Validar en staging antes de producción. Ver runbook:

`docs/optimia/operations/staging-connection-center-runbook.md`
