# Persistencia y backup — OptimiA + Evolution

## Volúmenes a proteger

| Volumen | Contenido | Crítico |
|---------|-----------|---------|
| `evolution_instances` | Sesiones WhatsApp Baileys | **Sí** |
| PostgreSQL Evolution | Config instancias / Chatwoot bridge | Sí |
| Redis Evolution | Cache Evolution | Medio |
| PostgreSQL Chatwoot | Conversaciones, conexiones OptimiA | **Sí** |
| Active Storage Chatwoot | Adjuntos | Sí |

## Scripts no destructivos

```bash
# Estado de volúmenes (si docker disponible)
bash scripts/optimia/backup-check.sh status

# Tamaños
bash scripts/optimia/backup-check.sh sizes

# Checklist de montajes
bash scripts/optimia/backup-check.sh verify-mounts

# Plan de backup
bash scripts/optimia/backup-check.sh backup-plan
```

## Procedimiento de backup (staging)

1. Snapshot del Droplet o backup de volúmenes en el proveedor.
2. `pg_dump` de `chatwoot_staging` → almacenamiento cifrado.
3. Backup de volumen `evolution_instances` (tar/rsync).
4. Backup PostgreSQL Evolution si aplica.
5. Registrar tag de imagen Chatwoot y versión Evolution.

## Restauración (solo staging)

1. Detener Evolution y Chatwoot workers.
2. Restaurar volúmenes/DB desde backup de prueba.
3. Verificar montaje `evolution_instances`.
4. Levantar Evolution `v2.3.7` fijado.
5. Levantar Chatwoot web + sidekiq.
6. `bundle exec rails optimia:channel_manager:sync_webhooks`
7. Prueba bidireccional con número de prueba.

**Nunca ejecutar restauración de prueba sobre producción.**

## Verificación de integridad

- Conexión en estado `ready` tras restore.
- `bundle exec rails 'optimia:channel_manager:diagnose[CONNECTION_ID]'` → `webhook_url_configured: true`
- Inbound + outbound de mensaje de prueba.
