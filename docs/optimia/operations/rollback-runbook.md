# Runbook: Rollback — OptimiA

> Procedimientos de recuperación. Clasificar el escenario antes de actuar.

## Árbol de decisión

```
¿Deploy falló?
├── ¿Migraciones se aplicaron?
│   ├── NO → Rollback simple (re-deploy tag anterior)
│   └── SÍ → ¿Migraciones reversibles?
│       ├── SÍ → Rollback imagen + verificar schema
│       └── NO → Restaurar backup PostgreSQL + tag anterior
└── ¿Solo worker afectado?
    └── Rollback solo servicio worker
```

---

## Escenario 1: Rollback sin migraciones

**Condición:** Nueva imagen desplegada pero `db:chatwoot_prepare` **no se ejecutó** o no hubo migraciones nuevas.

### Pasos

1. Identificar tag anterior (registro de deploy o inventario EasyPanel).
2. En EasyPanel, actualizar servicio **web** al tag anterior.
3. Actualizar servicio **worker** al mismo tag anterior.
4. Restart ambos servicios.
5. Verificar `GET /health` → 200.
6. Smoke test: login + conversación activa.

### Tiempo estimado

5–15 minutos.

### Riesgo de pérdida de datos

Ninguno (misma schema, misma DB).

---

## Escenario 2: Rollback con migraciones compatibles

**Condición:** Migraciones aplicadas son **aditivas** (nuevas columnas/tablas, sin eliminar datos).

### Pasos

1. Rollback imagen web + worker al tag anterior (igual que Escenario 1).
2. Verificar que la app anterior ignora columnas/tablas nuevas sin error.
3. Monitorear logs 30 minutos.
4. **No** revertir migraciones en DB (schema forward-compatible).

### Riesgo

Bajo si migraciones fueron solo aditivas. Documentar columnas huérfanas.

---

## Escenario 3: Rollback con migraciones incompatibles

**Condición:** Migraciones destructivas o que cambian comportamiento de forma incompatible.

### Pasos

1. **Detener** servicios web y worker (evitar escrituras).
2. Restaurar backup PostgreSQL **anterior al deploy** (ver [`backup-runbook.md`](backup-runbook.md)).
3. Restaurar storage si migración afectó archivos.
4. Desplegar tag de imagen anterior en web + worker.
5. Restart servicios.
6. Smoke tests completos.
7. Documentar RPO (datos perdidos entre backup y fallo).

### Tiempo estimado

30 minutos – 2 horas según tamaño de DB.

### Riesgo de pérdida de datos

**Alto** — se pierden transacciones posteriores al backup.

---

## Escenario 4: Restauración de base de datos

### Cuándo aplicar

- Corrupción de datos.
- Migración fallida a medias.
- Rollback incompatible (Escenario 3).

### Procedimiento

```bash
# 1. Detener web y worker
# 2. Restaurar dump
pg_restore -h $POSTGRES_HOST -U $POSTGRES_USERNAME \
  -d $POSTGRES_DATABASE --clean --if-exists \
  optimia-pg-YYYYMMDD.dump

# 3. Verificar
psql -h $POSTGRES_HOST -U $POSTGRES_USERNAME -d $POSTGRES_DATABASE \
  -c "SELECT COUNT(*) FROM accounts;"
```

### Post-restauración

- [ ] Desplegar imagen compatible con schema restaurado
- [ ] Verificar integridad de conversaciones y contactos
- [ ] Reindexar si usa Elasticsearch (futuro)

---

## Escenario 5: Restauración de storage

### Modo local

```bash
# Detener web/worker
tar -xzf optimia-storage-YYYYMMDD.tar.gz -C /app/
# Restart servicios
```

### Modo S3/R2

- Restaurar versión anterior del objeto desde versioning.
- O sync desde backup off-site.

### Verificación

- [ ] Adjunto de prueba descargable desde UI
- [ ] Avatar de agente visible

---

## Escenario 6: Recuperación del worker

**Condición:** Web funciona pero jobs no se procesan.

### Diagnóstico

1. ¿Servicio worker existe en EasyPanel?
2. ¿Proceso Sidekiq activo?
3. ¿Redis accesible desde worker?
4. ¿Mismas credenciales PG/Redis que web?

### Recuperación

1. Si worker no existe: **crear servicio** con misma imagen/tag que web.
2. Si worker crashea: revisar logs, rollback tag si necesario.
3. Si Redis caído: restaurar Redis o restart servicio Redis.
4. Verificar queue: jobs pendientes empiezan a procesarse.

### Riesgo si worker ausente prolongado

Emails, webhooks y WhatsApp async se acumulan en cola o fallan.

---

## Registro de rollback

| Campo | Valor |
|-------|-------|
| Fecha/hora inicio | |
| Escenario | 1 / 2 / 3 / 4 / 5 / 6 |
| Tag revertido desde | |
| Tag revertido hacia | |
| Migraciones involucradas | ☐ Sí ☐ No |
| Backup restaurado | ☐ PG ☐ Storage ☐ Ninguno |
| RPO (datos perdidos) | |
| RTO (tiempo recuperación) | |
| Smoke tests post-rollback | ☐ Pass ☐ Fail |
| Incidente documentado | ☐ Sí |

---

## Prevención

- Siempre backup pre-deploy.
- Nunca usar `:latest` en producción.
- Promover mismo tag staging → prod.
- Documentar cada deploy con tag y digest.
- Probar restore mensual en staging.
