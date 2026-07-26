# Rollback — OptimiA

## Principio

Rollback = restaurar digest/imagen conocida buena. **Nunca** usar `latest` o tags flotantes en producción.

## Producción actual congelada (v0.1.9)

| Campo | Valor |
|-------|-------|
| Imagen | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Digest | Obtener con `docker manifest inspect` en entorno con acceso |
| Estado | **No modificar** hasta migración planificada |

## Rollback desde v0.2.x a v0.1.9

1. Detener deploy en curso si aplica
2. EasyPanel → web + worker → imagen/digest v0.1.9
3. Verificar migraciones BD (puede requerir `db:rollback` — evaluar con backup)
4. Smoke tests: login, inbox, WhatsApp

## Rollback entre versiones nuevas (post-migración registry)

1. Identificar digest bueno en artifact `production-image-metadata.json`
2. EasyPanel → actualizar por digest `sha256:...`
3. Reiniciar worker Sidekiq
4. Validar colas Sidekiq

## Imágenes legacy — retención 90 días

Mantener disponibles:

- `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` (prod actual)
- Tags staging anteriores en `ghcr.io/pablo-paez-dev/chatwoot`

No borrar paquetes hasta validar rollback exitoso.

## Comandos útiles

```bash
# Inspeccionar imagen candidata
bash scripts/optimia/image-inspect.sh ghcr.io/pablo-paez-dev/chatwoot:cw-4.10.1-optimia-0.2.0

# Listar metadata de release
bash scripts/optimia/release-metadata.sh 0.1.9 4.10.1 $(git rev-parse HEAD) production
```
