# OptimiA — Evolution pinned version

## Versión fijada

| Componente | Imagen | Notas |
|------------|--------|-------|
| Evolution API | `evoapicloud/evolution-api:v2.3.7` | Validado con OptimiA 0.1.6 |
| PostgreSQL Evolution | `postgres:16-alpine` | No usar `latest` |
| Redis Evolution | `redis:7.4-alpine` | No usar `latest` |

Digest amd64 de referencia para `v2.3.7`:

`sha256:456b4104b0ddffbb092d6b3c0560a4ae86fc3e014e885b882aca4b1b371dfc81`

## Reemplazo obligatorio

Cambiar cualquier referencia `evoapicloud/evolution-api:latest` por `evoapicloud/evolution-api:v2.3.7`.

Plantilla: `scripts/optimia/evolution-docker-compose.example.yml`

## Upgrade (fuera de este sprint)

1. Probar nueva versión en staging aislado.
2. Validar inbound/outbound + webhook sync.
3. Documentar breaking changes Evolution.
4. Actualizar digest y tag en runbook.
5. Nunca saltar de `v2.3.7` a `v2.4.x` sin revisar licenciamiento Evolution Foundation.

## Rollback

1. Restaurar tag `v2.3.7` en compose.
2. Conservar volumen `evolution_instances` (sesiones WhatsApp).
3. Reiniciar solo `evolution-api`.
4. Verificar `GET /instance/connectionState/{instance}`.

## Compatibilidad OptimiA

- Channel Manager usa `/chatwoot/set`, `/chatwoot/find`, `/instance/connectionState`.
- Outbound nativo vía `Channel::Api.webhook_url` → `/chatwoot/webhook/{instance}`.
- No actualizar Evolution durante el piloto productivo inicial.
