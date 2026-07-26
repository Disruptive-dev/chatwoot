# Runbook — Build Staging OptimiA

## Prerrequisitos

- Merge a `develop` con versión deseada (ej. v0.2.0)
- Variables GitHub configuradas (ver [README.md](./README.md))
- **No** se requiere modificar producción

## Opción A — Tag push

```bash
git tag staging-cw-4.10.1-optimia-0.2.0
git push origin staging-cw-4.10.1-optimia-0.2.0
```

Dispara `optimia-build-staging.yml` automáticamente.

## Opción B — Manual (workflow_dispatch)

1. GitHub → Actions → **OptimiA Build Staging**
2. Run workflow en rama `develop`
3. Inputs:
   - `optimia_version`: `0.2.0`
   - `chatwoot_version`: `4.10.1`
   - `frontend_url`: (vacío = default staging)
   - `dry_run`: `false` para publicar

## Verificar resultado

1. Abrir job summary → copiar **Digest** `sha256:...`
2. Descargar artifact `staging-image-metadata.json`
3. Validar imagen:

```bash
bash scripts/optimia/image-inspect.sh ghcr.io/pablo-paez-dev/chatwoot:staging-cw-4.10.1-optimia-0.2.0
```

## Deploy staging (acción humana — fuera de CI)

1. EasyPanel → servicio staging → actualizar imagen por **digest**
2. `bundle exec rails db:migrate`
3. Smoke tests: `docs/optimia/operations/staging-connection-center-runbook.md`

## Dry run (sin publicar)

Workflow dispatch con `dry_run: true` — valida build sin push a GHCR.

## Troubleshooting

| Error | Causa | Acción |
|-------|-------|--------|
| Invalid tag format | Tag no cumple patrón | Usar `staging-cw-X.Y.Z-optimia-A.B.C` |
| 403 GHCR | Permisos token | Verificar `packages: write` |
| Build en cola | Concurrency | Esperar run anterior (`optimia-staging-build`) |
