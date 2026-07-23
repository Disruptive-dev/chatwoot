# Runbook — WhatsApp Connection Center (Staging)

## Pre-requisitos

- [ ] Staging desplegado (`staging.optimia.spectra-metrics.com`)
- [ ] Evolution API accesible desde staging
- [ ] Variables configuradas en servicio `chatwoot` staging:

```env
EVOLUTION_API_URL=https://evo-api.spectra-metrics.com
EVOLUTION_API_KEY=<secret>
OPTIMIA_CHATWOOT_PUBLIC_URL=https://staging.optimia.spectra-metrics.com
OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN=<chatwoot-api-token>
OPTIMIA_CHANNEL_MANAGER_ENABLED=true
```

- [ ] Cuenta de prueba con feature `optimia_channel_manager` habilitado

## Smoke test

1. Login como administrador en staging.
2. Ir a **Configuración → WhatsApp** (sidebar).
3. **Conectar número** → ingresar nombre → iniciar.
4. Verificar QR visible y countdown activo.
5. Escanear QR con WhatsApp de prueba.
6. Verificar transición a estado `ready` e `inbox_id` asignado.
7. Enviar mensaje de prueba → verificar llegada vía integración Evolution ↔ Chatwoot.
8. **Desconectar** → verificar estado `disconnected`.
9. **Reconectar** → nuevo QR → volver a `ready`.

## Rollback

1. Deshabilitar feature flag en cuenta o `OPTIMIA_CHANNEL_MANAGER_ENABLED=false`.
2. Revertir imagen staging al tag anterior.
3. Las tablas `optimia_channel_connections*` son aditivas — no bloquean rollback de app.
4. Instancias Evolution en staging pueden quedar activas (no se borran físicamente).

## Troubleshooting

| Síntoma | Acción |
|---------|--------|
| `feature_disabled` | Habilitar `optimia_channel_manager` en cuenta |
| `evolution_not_configured` | Verificar ENV Evolution en web + sidekiq |
| QR no aparece | Revisar logs `evolution_api_request` |
| Queda en `syncing` | Verificar `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN` |
| 403 en API | Usuario debe ser administrador |

## Logs

```bash
# Buscar eventos
grep optimia_channel_connection /var/log/chatwoot/production.log
grep evolution_api_request /var/log/chatwoot/production.log
```
