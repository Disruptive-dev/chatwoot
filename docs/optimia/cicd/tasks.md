# OptimiA CI/CD — Tasks v0.2.1

## Completadas

- [x] T-001 Diagnóstico Git y lectura docs proyecto
- [x] T-002 Auditoría 17 workflows
- [x] T-003 Búsqueda referencias registry/secrets
- [x] T-004 Verificación org DSW-Factory
- [x] T-005 `docs/optimia/cicd/constitution.md`
- [x] T-006 `docs/optimia/cicd/spec.md`
- [x] T-007 `docs/optimia/cicd/decisions.md` (ADR-001 a ADR-004)
- [x] T-008 `docs/optimia/cicd/plan.md`
- [x] T-009 `docs/optimia/cicd/tasks.md`
- [x] T-010 Crear `optimia-ci.yml`
- [x] T-011 Crear `optimia-build-staging.yml`
- [x] T-012 Crear `optimia-build-production.yml`
- [x] T-013 Guards upstream workflows
- [x] T-014 Deprecar workflows legacy OptimiA
- [x] T-015 Scripts `scripts/optimia/*.sh`
- [x] T-016 Actualizar `staging-war-room.sh`
- [x] T-017 Documentación runbooks y README
- [x] T-018 Actualizar PROJECT-STATUS, SPRINT-HANDOFF, CHANGELOG
- [x] T-019 Validación validate-cicd.sh
- [ ] T-020 Commit, push, PR draft

## Pendientes (acción humana post-merge)

- [ ] T-021 Configurar variables repo en GitHub Settings
- [ ] T-022 Crear environment `production` con required reviewers
- [ ] T-023 (Opcional) Crear `GHCR_TOKEN` para DSW-Factory
- [ ] T-024 Autorizar primer build staging v0.2.0
- [ ] T-025 Deploy staging EasyPanel
- [ ] T-026 Smoke tests staging
- [ ] T-027 Aprobar build producción v0.2.0

## Criterios de aceptación

1. Exactamente 3 workflows OptimiA pipeline (CI + staging + prod)
2. Cero referencias activas a `disruptive-dev` en workflows ejecutables
3. Cero publish Docker Hub en fork
4. Push develop no dispara producción
5. Producción solo manual con confirmación
6. Documentación completa en `docs/optimia/cicd/`
7. PR draft abierto, sin merge, sin deploy
