# Runbook — Piloto productivo WhatsApp (OptimiA)

## FASE A — PREPARACIÓN

- [ ] Snapshot del Droplet productivo
- [ ] Backup PostgreSQL Chatwoot prod
- [ ] Backup volúmenes Evolution (`evolution_instances`, PG, Redis)
- [ ] Verificar espacio en disco (>30% libre recomendado)
- [ ] Verificar CPU/RAM bajo carga normal
- [ ] Rotar secretos según `docs/optimia/security/secrets-matrix.md`
- [ ] Fijar imágenes:
  - Chatwoot prod: tag acordado (no staging)
  - Evolution: `evoapicloud/evolution-api:v2.3.7`
- [ ] Documentar rollback a imagen anterior

## FASE B — DESPLIEGUE

- [ ] Construir imagen productiva (fuera de este sprint si aplica)
- [ ] Actualizar servicio web prod
- [ ] Actualizar Sidekiq prod
- [ ] Ejecutar migraciones: `POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:migrate`
- [ ] `bundle exec rails optimia:channel_manager:sync_webhooks`
- [ ] `bundle exec rails optimia:channel_manager:health`
- [ ] No tocar clientes/cuentas existentes sin feature flag

## FASE C — PILOTO (un solo número)

- [ ] Habilitar `optimia_channel_manager` solo en cuenta piloto
- [ ] Conectar número vía Settings → WhatsApp → Connect
- [ ] Escanear QR
- [ ] Verificar estado `ready`
- [ ] Inbound: mensaje externo → aparece en OptimiA
- [ ] Outbound: respuesta agente → llega a WhatsApp
- [ ] Probar imagen/documento/audio
- [ ] Simular desconexión y reconexión administrada
- [ ] Monitorear 24–48h (job cada 2 min + alertas)

## FASE D — CRITERIOS DE APROBACIÓN

- [ ] Sin mensajes duplicados
- [ ] Sin pérdida de mensajes
- [ ] Sin HTTP 500 en API conexiones
- [ ] Sin desconexiones no recuperadas sin intervención
- [ ] Webhook operativo (`webhook_configured: true`)
- [ ] Backups verificados en staging
- [ ] Logs sin secretos
- [ ] Alertas internas con cooldown funcionando

## FASE E — ROLLBACK

1. Detener despliegue de nuevas conexiones piloto (feature flag off).
2. Revertir imagen Chatwoot web + sidekiq al tag anterior.
3. **Conservar** bases de datos y `evolution_instances`.
4. Restaurar backup solo si corrupción demostrada.
5. Verificar servicios core Chatwoot no-WhatsApp intactos.

## Comandos operativos

```bash
bundle exec rails optimia:channel_manager:list_connections
bundle exec rails 'optimia:channel_manager:diagnose[CONNECTION_ID]'
bundle exec rails optimia:channel_manager:sync_webhooks
bundle exec rails optimia:channel_manager:monitor_once
```

## EasyPanel staging (pre-prod validation)

1. Imagen: `ghcr.io/pablo-paez-dev/chatwoot:staging-cw-4.10.1-optimia-0.1.7`
2. Migrar DB
3. Reiniciar web + sidekiq
4. Ejecutar `sync_webhooks` y prueba bidireccional
