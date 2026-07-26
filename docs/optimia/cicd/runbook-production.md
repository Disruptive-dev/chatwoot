# Runbook — Build Producción OptimiA

## ⚠️ Requisitos previos obligatorios

1. Imagen staging **publicada y validada** con smoke tests
2. Digest staging copiado del job summary
3. Environment `production` configurado con required reviewers
4. Aprobación explícita del propietario
5. **Producción actual v0.1.9 NO debe modificarse hasta completar este proceso**

## Procedimiento

1. GitHub → Actions → **OptimiA Build Production**
2. Run workflow en rama `develop` (o tag de release)
3. Completar inputs:

| Input | Valor ejemplo |
|-------|---------------|
| `optimia_version` | `0.2.0` |
| `chatwoot_version` | `4.10.1` |
| `staging_digest` | `sha256:abc123...` (del staging validado) |
| `confirm_production` | `DEPLOY_OPTIMIA` (exacto) |

4. Esperar aprobación del environment `production`
5. Copiar digest del job summary
6. Descargar artifact `production-image-metadata.json`

## Tag resultante

```
ghcr.io/pablo-paez-dev/chatwoot:cw-4.10.1-optimia-0.2.0
```

## Deploy EasyPanel (manual — NO automático)

1. Backup BD producción
2. EasyPanel → actualizar imagen web y worker por **digest**
3. Verificar Sidekiq operativo
4. Smoke tests producción

## Protecciones

- Tag duplicado → workflow **falla** (no sobrescribe)
- `confirm_production` incorrecto → **falla**
- Push a `develop` → **no** dispara este workflow
- Sin `staging_digest` válido → **falla**

## Rollback

Ver [rollback.md](./rollback.md) — volver a digest `v0.1.9` congelado.
