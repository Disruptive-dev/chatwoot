# Matriz de secretos — OptimiA Channel Manager

> No incluir valores reales en este documento ni en commits.

## Staging

| Secreto | Servicio | Rotación antes del piloto |
|---------|----------|---------------------------|
| `EVOLUTION_API_KEY` | Chatwoot + Evolution | Sí |
| `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN` | Chatwoot | Sí |
| `SECRET_KEY_BASE` | Chatwoot | Sí |
| PostgreSQL Chatwoot (`POSTGRES_PASSWORD`) | Chatwoot DB | Sí |
| PostgreSQL Evolution | Evolution DB | Sí |
| Redis Evolution | Evolution | Sí |
| Redis Chatwoot (`REDIS_URL`) | Chatwoot/Sidekiq | Sí |

## Production

| Regla | Detalle |
|-------|---------|
| Separación total | Nunca copiar credenciales de staging |
| Tokens de prueba | Invalidar tokens usados en staging |
| API keys | Generar nuevas en Evolution prod |
| Chatwoot token | Usuario/bot dedicado prod con scope mínimo |
| Prefijo instancia | `OPTIMIA_EVOLUTION_INSTANCE_PREFIX` distinto (ej. `optimia-prod`) |

## Checklist obligatorio pre-piloto

- [ ] Rotar `EVOLUTION_API_KEY` prod
- [ ] Rotar `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN` prod
- [ ] Rotar passwords PostgreSQL/Redis prod
- [ ] Verificar que logs no imprimen tokens (`grep -i token production.log` sin matches sensibles)
- [ ] Confirmar ENV distintos entre staging y prod en EasyPanel
- [ ] Documentar custodio de cada secreto (sin valores)

## Canales futuros (documentado)

| Canal | Estado sprint |
|-------|---------------|
| Notificación in-app OptimiA | Operativo (`optimia_channel_connection_alerts`) |
| Email administradores | Documentado — usar mailer dedicado post-piloto |
| Webhook Spectra Flow | Documentado — integrar en `ConnectionAlertService` |
