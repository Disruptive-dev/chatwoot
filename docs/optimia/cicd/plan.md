# OptimiA CI/CD — Plan de implementación v0.2.1

## Fase 0 — Preparación ✅

- [x] Diagnóstico Git (`develop` @ `1f224c885`, sin divergencia)
- [x] Lectura `PROJECT-STATUS.md`, `SPRINT-HANDOFF.md`
- [x] Rama `cursor/optimia-cicd-cleanup-ce69`

## Fase 1 — Auditoría ✅

- [x] Inventario 17 workflows
- [x] Clasificación y matriz de riesgo
- [x] Búsqueda referencias `disruptive-dev`, `pablo-paez-dev`, `dsw-factory`
- [x] Verificación org `DSW-Factory` (existe; publish cross-org bloqueado)

## Fase 2 — Decisiones ADR ✅

- [x] ADR-001 Registry
- [x] ADR-002 CI
- [x] ADR-003 Tags
- [x] ADR-004 Producción

## Fase 3 — Desactivar ruido upstream

| Workflow | Acción |
|----------|--------|
| `publish_foss_docker.yml` | Guard `chatwoot/chatwoot` en jobs |
| `publish_ee_docker.yml` | Guard |
| `publish_codespace_image.yml` | Guard |
| `deploy_check.yml` | Guard |
| `nightly_installer.yml` | Guard |
| `stale.yml` | Guard |
| `logging_percentage_check.yml` | Guard |
| `frontend-fe.yml` | Guard |
| `run_foss_spec.yml` | Guard |
| `test_docker_build.yml` | Guard |
| `build-optimia-chatwoot.yml` | Deprecar → solo dispatch con error |
| `build-optimia-chatwoot-staging.yml` | Deprecar → solo dispatch con error |

## Fase 4 — `optimia-ci.yml`

Crear workflow único con 8 jobs + summary.

## Fase 5 — `optimia-build-staging.yml`

- Registry parametrizado
- Validación tag
- Digest + metadata artifact
- SBOM

## Fase 6 — `optimia-build-production.yml`

- Environment production
- Confirmación `DEPLOY_OPTIMIA`
- Check tag duplicado
- Sin deploy

## Fase 7 — Seguridad GHCR

- `permissions: contents: read` (CI)
- `permissions: packages: write` (builds)
- Token cross-org documentado, no implementado sin secret

## Fase 8 — Variables

Documentar en `spec.md` y `README.md`. Configurar en GitHub UI (acción humana).

## Fase 9 — Documentación

- `docs/optimia/cicd/README.md`
- Runbooks staging/producción/rollback
- `registry-migration.md`
- Actualizar `PROJECT-STATUS.md`, `SPRINT-HANDOFF.md`, `CHANGELOG.md`

## Fase 10 — Scripts

- `scripts/optimia/ci-status.sh`
- `scripts/optimia/image-inspect.sh`
- `scripts/optimia/release-metadata.sh`
- `scripts/optimia/validate-cicd.sh`
- Corregir `scripts/staging-war-room.sh`

## Fase 11 — Concurrency

- CI: cancel-in-progress en PR
- Staging: `optimia-staging-build`, no cancel
- Production: `optimia-production-build`, no cancel

## Fase 12 — Validación

- `actionlint` si disponible
- `scripts/optimia/validate-cicd.sh`
- Revisión manual expresiones

## Fase 13 — Tests del pipeline

Script `validate-cicd.sh` verifica 15 condiciones.

## Fase 14 — Migración v0.2.0 (sin ejecutar)

1. Merge PR CI/CD cleanup
2. Configurar variables GitHub
3. Ejecutar `optimia-ci` en PR
4. **Autorización humana** → `optimia-build-staging` tag `staging-cw-4.10.1-optimia-0.2.0`
5. Obtener digest del summary
6. Deploy staging manual EasyPanel (fuera de scope)
7. Smoke tests
8. Aprobación → `optimia-build-production`
9. EasyPanel prod manual por digest (futuro)

## Fase 15 — Alcance estricto

**No ejecutado:** deploy, EasyPanel, Evolution, producción publish.

## Riesgos pendientes

| # | Riesgo | Mitigación |
|---|--------|------------|
| 1 | DSW-Factory sin GHCR_TOKEN | Fallback `pablo-paez-dev` |
| 2 | Environment `production` no configurado en GitHub | Documentar setup reviewer |
| 3 | Imagen v0.1.9 sigue en disruptive-dev | No tocar; rollback documentado |
| 4 | 129 vulns JS (`pnpm audit`) | Fuera de scope sprint |
| 5 | Suite RSpec reducida (4 nodos) | Ampliar si fallan regresiones |
