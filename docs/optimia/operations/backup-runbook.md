# Runbook: Backup — OptimiA

> Procedimientos conceptuales. **No ejecutar en producción sin autorización explícita.**

## 1. Alcance

Componentes a respaldar:

| Componente | Prioridad | Frecuencia recomendada |
|------------|-----------|------------------------|
| PostgreSQL | **Crítica** | Diaria + antes de cada deploy |
| Active Storage | **Crítica** | Diaria |
| Redis | Media | Diaria (RDB) o aceptar pérdida de cola |
| Config EasyPanel | Alta | Antes de cada cambio |
| Secretos / ENV | Alta | En vault seguro, no en repo |

## 2. Backup PostgreSQL

### 2.1 Dump lógico

```bash
# Conceptual — ajustar host/credenciales según entorno
pg_dump -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
  --format=custom --file=optimia-pg-$(date +%Y%m%d-%H%M%S).dump
```

### 2.2 Validación de integridad

```bash
pg_restore --list optimia-pg-YYYYMMDD.dump | head -20
# Verificar que el archivo no está vacío y lista tablas
```

### 2.3 Retención

- Mínimo 30 días en producción.
- Retener backup pre-deploy por 90 días.

## 3. Backup Active Storage

### 3.1 Modo local (volumen)

```bash
# Snapshot o tar del volumen
tar -czf optimia-storage-$(date +%Y%m%d).tar.gz /app/storage/
```

### 3.2 Modo S3/R2

- Habilitar **versioning** en el bucket.
- Configurar lifecycle policy (retención 90 días mínimo).
- Replicación cross-region opcional.

```bash
# Sync incremental (conceptual)
aws s3 sync s3://$S3_BUCKET_NAME ./backup-storage/ --delete
```

## 4. Backup Redis

Redis es mayormente efímero (colas). Backup opcional:

```bash
redis-cli -a $REDIS_PASSWORD BGSAVE
# Copiar dump.rdb del volumen Redis
```

**Nota:** En caso de pérdida de Redis, Sidekiq reencola jobs pendientes; no es crítico como PostgreSQL.

## 5. Exportación configuración EasyPanel

Documentar manualmente (sin secretos):

- [ ] Nombre de servicios y tags de imagen
- [ ] Comandos de inicio
- [ ] Puertos y healthchecks
- [ ] Volúmenes y rutas de montaje
- [ ] **Nombres** de variables ENV (no valores)
- [ ] Políticas de restart y réplicas
- [ ] Dominios y certificados TLS

Usar plantilla: [`easypanel-inventory-template.md`](easypanel-inventory-template.md).

## 6. Prueba de restauración

### Frecuencia

Mensual en staging; trimestral en producción (en ventana de mantenimiento).

### Procedimiento (staging)

1. Crear entorno staging aislado.
2. Restaurar último dump PostgreSQL.
3. Restaurar storage (volumen o bucket).
4. Desplegar misma imagen/tag que prod.
5. Configurar ENV de staging.
6. Ejecutar smoke tests:
   - Login
   - Listar conversaciones
   - Ver adjunto existente
   - Enviar mensaje de prueba
7. Documentar tiempo de restauración (RTO) y punto de recuperación (RPO).

### Criterios de éxito

- [ ] Datos de cuentas y conversaciones accesibles
- [ ] Adjuntos descargables
- [ ] Login funcional
- [ ] Tiempo de restauración documentado

## 7. Almacenamiento de backups

| Ubicación | Requisito |
|-----------|-----------|
| Off-site | Obligatorio (distinto del servidor prod) |
| Cifrado at-rest | Obligatorio |
| Acceso | Mínimo privilegio, auditado |
| Secretos | Nunca en el mismo bucket que dumps sin cifrar |

## 8. Checklist pre-deploy

Antes de cada deploy a producción:

- [ ] Backup PostgreSQL reciente (< 24h)
- [ ] Backup storage reciente
- [ ] Export config EasyPanel actualizada
- [ ] Tag de imagen anterior documentado para rollback
