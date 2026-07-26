# SPRINT-HANDOFF — OptimiA

> Registro append-only de handoffs entre sprints y sesiones.  
> No borrar entradas anteriores.

---

## Sprint 0 — Trazabilidad y baseline

| Campo | Valor |
|-------|-------|
| **Sprint** | Sprint 0 — Trazabilidad y baseline |
| **Entorno** | Cursor Online |
| **Rama** | `develop` |
| **Commit inicial** | `462802c9e` |
| **Commit documentación** | `5ab2bb5e4` |
| **Commit continuidad** | Ver `git log` tras cierre Sprint 0 |
| **Deploy** | No |
| **Producción modificada** | No |
| **Push Sprint 0 docs** | Pendiente al inicio del cierre Sprint 0 → completado en cierre |
| **Fecha cierre** | 2026-07-23 |

### Entregables

- 19 archivos en `docs/optimia/` (arquitectura, operaciones, seguridad, inventario, ADRs, upgrades).
- Remote `upstream` configurado: `https://github.com/chatwoot/chatwoot.git`.
- Baseline fork identificado: `6a7cbcf5` (`package.json` 4.10.1, padre de `ac4ec0fbe`).
- Tag local creado: `chatwoot-base/v4.10.1` → `6a7cbcf5`.
- Protocolo de continuidad cross-session (AGENTS.md, `.cursor/rules/`, `docs/project/`, `scripts/project-context.sh`).
- Checklist manual EasyPanel: `docs/optimia/operations/easypanel-production-checklist.md`.

### Controles ejecutados

| Control | Resultado |
|---------|-----------|
| Validación commit `5ab2bb5e4` (solo docs) | ✅ |
| YAML workflows (16 archivos) | ✅ |
| `pnpm audit` | ⚠️ 129 vulnerabilidades |
| `bundle audit` | ⏳ Pendiente |
| `gitleaks` | ⏳ Pendiente |
| Tests Spectra (RSpec) | ⏳ Ruby no disponible en entorno |
| Tests internalCommands (Vitest) | ⏳ node_modules ausente |
| Docker build | ⏳ No ejecutado |
| Búsqueda secretos en repo | ✅ No detectados |

### Riesgos identificados

| # | Riesgo | Severidad |
|---|--------|-----------|
| 1 | Trazabilidad EasyPanel no verificada | Alta |
| 2 | Worker Sidekiq posiblemente ausente en prod | Alta |
| 3 | Dockerfile raíz solo web (sin Sidekiq) | Alta |
| 4 | 713 commits detrás de upstream | Media |
| 5 | 129 vulnerabilidades JS (`pnpm audit`) | Media |
| 6 | Repo en cuenta personal | Media |

### Pendiente

- [ ] Usuario completa checklist EasyPanel.
- [ ] Aprobación ADR-001, ADR-002, ADR-003 por propietario.
- [ ] `bundle audit` y `gitleaks` en CI.
- [ ] Verificar worker en producción.

### Próximo paso exacto

1. Usuario abre EasyPanel y completa `easypanel-production-checklist.md` (solo lectura, sin modificar nada).
2. Usuario envía datos recopilados (sin secretos) + capturas indicadas.
3. **No iniciar Sprint 1 técnico** hasta recibir esa información.
4. Sprint 1 (cuando autorizado): inventario real EasyPanel, backup prod, aprobación ADRs.

---

## Sprint 1 — Preparación staging aislado

| Campo | Valor |
|-------|-------|
| **Sprint** | Sprint 1 — Preparación staging aislado |
| **Entorno** | Cursor Online |
| **Rama** | `develop` |
| **Commit base** | `86d316283` |
| **Deploy** | No |
| **Producción modificada** | No |
| **EasyPanel modificado** | No |
| **Push** | Pendiente aprobación |

### Contexto producción verificado (input usuario)

- Imagen: `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6`
- Servicios: `chatwoot`, `chatwoot-sidekiq`, `chatwoot-db`, `chatwoot-redis`
- Web y worker: misma imagen; Sidekiq operativo
- Prod con clientes reales — **no tocar**

### Entregables Sprint 1 (preparación, sin deploy)

- `docs/optimia/environments/` — arquitectura, imágenes, variables, web/worker, aislamiento
- `docs/optimia/operations/easypanel-staging-setup-guide.md` — guía manual paso a paso
- `.github/workflows/build-optimia-chatwoot-staging.yml` — build staging solo manual
- Actualización `PROJECT-STATUS.md`, `DECISIONS.md`, `CHANGELOG.md`

### Controles

| Control | Resultado |
|---------|-----------|
| Workflow prod sin modificar | ✅ |
| Tag prod `v4.10.1-optimia.6` sin modificar | ✅ |
| Sin conexión a EasyPanel prod | ✅ |
| YAML workflow staging válido | ✅ |
| Documentación sin secretos | ✅ |

### Próximo paso exacto

1. Push commit Sprint 1 (si aprobado).
2. GitHub Actions → Run workflow → `Build Optimia Chatwoot Staging Image`.
3. Operador: crear proyecto staging en EasyPanel (guía manual).
4. Smoke tests staging.
5. **No** promover a prod hasta validación completa.

---

## Sprint 2 — Channel Manager Foundation + WhatsApp Connection Center

| Campo | Valor |
|-------|-------|
| **Sprint** | Sprint 2 — Channel Manager + Connection Center |
| **Entorno** | Cursor Cloud Agent |
| **Rama** | `develop` (sin rama paralela) |
| **Deploy** | No |
| **Producción modificada** | No |

### Entregables

- Modelo `OptimiaChannelConnection` + auditoría + máquina de estados
- Provider Registry + Evolution Adapter (`lib/integrations/evolution/`, `lib/integrations/optimia/channel_manager/`)
- API `optimia/whatsapp/connections` (CRUD parcial + QR + status + reconnect + disconnect)
- UI `Configuración → WhatsApp` (listado, wizard, QR, polling)
- Provisioning idempotente de inbox Chatwoot (`Channel::Api`)
- Feature flag `optimia_channel_manager`
- RFC, ADR-004, seguridad, runbook staging
- Specs RSpec (modelo, servicio, request)

### Variables ENV nuevas

- `EVOLUTION_API_URL`, `EVOLUTION_API_KEY`
- `OPTIMIA_CHATWOOT_PUBLIC_URL`, `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN`
- `OPTIMIA_CHANNEL_MANAGER_ENABLED`, `EVOLUTION_PAIRING_CODE_SUPPORTED`

### Próximo paso exacto

1. Push `develop` y build imagen staging.
2. Configurar ENV Evolution en staging.
3. Smoke tests según `staging-connection-center-runbook.md`.

---

## Sprint 3 — Technical Health Center v0.2.0

| Campo | Valor |
|-------|-------|
| **Sprint** | Sprint 3 — Technical Health Center |
| **Entorno** | Cursor Cloud Agent |
| **Rama** | `cursor/technical-health-center-3da0` |
| **Versión OptimiA** | 0.2.0 |
| **Deploy** | No |
| **Producción modificada** | No |

### Entregables

- NOC Dashboard con 12 componentes monitoreados (`Orchestrator` + checkers).
- Alert Detector (11 reglas) + gestión de alertas e incidentes.
- Diagnostic Center (score 0–100) por plataforma y por conexión WhatsApp.
- Connection Monitor + Timeline Builder integrado con Channel Manager.
- Deployment Center + modelo `OptimiaDeploymentRecord`.
- API interna `/internal/health/*` con autenticación por token.
- UI Super Admin `/super_admin/technical_health`.
- Job `Optimia::TechnicalHealth::CollectHealthJob` (cron `*/5 * * * *`).
- Migración `20260724160000_create_optimia_technical_health_tables` (6 tablas).
- Documentación `docs/optimia/technical-health/` (README, audit, risk-matrix, runbooks, executive-summary).
- Specs RSpec (orchestrator, alert detector, diagnostic, controllers, job).

### Modelos nuevos

- `OptimiaTechnicalHealthCheck`, `OptimiaTechnicalAlert`, `OptimiaTechnicalIncident`
- `OptimiaTechnicalTimelineEvent`, `OptimiaTechnicalMetricSnapshot`, `OptimiaDeploymentRecord`

### Variables ENV nuevas

- `OPTIMIA_INTERNAL_HEALTH_TOKEN`
- `OPTIMIA_DEPLOY_VERSION`, `OPTIMIA_DEPLOY_COMMIT_SHA`, `OPTIMIA_DEPLOY_IMAGE_DIGEST`, `OPTIMIA_DEPLOY_IMAGE_TAG`
- `OPTIMIA_SWARM_SERVICE`, `OPTIMIA_NODE_ROLE`

### Controles

| Control | Resultado |
|---------|-----------|
| Producción sin modificar | ✅ |
| Deploy no ejecutado | ✅ |
| Documentación en español | ✅ |
| Sanitización payloads sensibles | ✅ |
| Specs RSpec añadidos | ✅ |

### Próximo paso exacto

1. Merge a `develop` y build imagen staging `staging-cw-4.10.1-optimia-0.2.0`.
2. Ejecutar migración BD en staging.
3. Configurar `OPTIMIA_INTERNAL_HEALTH_TOKEN` y ENV deploy en EasyPanel staging.
4. Smoke tests según `docs/optimia/technical-health/runbooks.md`.
5. QA staging completo antes de planificar prod.

---

## Sprint v0.2.1 — CI/CD Platform Cleanup

| Campo | Valor |
|-------|-------|
| **Sprint** | v0.2.1 — CI/CD Platform Cleanup |
| **Entorno** | Cursor Cloud Agent |
| **Rama** | `cursor/optimia-cicd-cleanup-ce69` |
| **Commit base** | `1f224c885` (develop) |
| **Deploy** | No |
| **Producción modificada** | No |
| **EasyPanel modificado** | No |
| **Imagen producción publicada** | No |
| **Staging desplegado** | No |

### Causa raíz

- Workflow prod (`build-optimia-chatwoot.yml`) publicaba en `ghcr.io/disruptive-dev/chatwoot` sin permisos.
- Push automático a `develop` disparaba builds prod + upstream Docker Hub.
- 17 workflows activos con duplicación CI y colas de runners.
- Registries fragmentados: `disruptive-dev`, `pablo-paez-dev`, `dsw-factory` (doc).

### Entregables

- Auditoría 17 workflows → `docs/optimia/cicd/spec.md`
- ADR CI/CD 001–004 → `docs/optimia/cicd/decisions.md`
- `optimia-ci.yml`, `optimia-build-staging.yml`, `optimia-build-production.yml`
- Guards upstream en 11 workflows
- Legacy `build-optimia-chatwoot*.yml` deprecados
- Scripts `scripts/optimia/*.sh`
- Documentación runbooks y migración registry

### Registry elegido

| Rol | Valor |
|-----|-------|
| Objetivo | `ghcr.io/dsw-factory/optimia-chatwoot` |
| Fallback activo | `ghcr.io/pablo-paez-dev/chatwoot` |
| Bloqueo | GHCR cross-org sin `GHCR_TOKEN` |

### Controles

| Control | Resultado |
|---------|-----------|
| Producción sin modificar | ✅ |
| EasyPanel sin tocar | ✅ |
| Sin publish prod | ✅ |
| Sin deploy staging | ✅ |
| `validate-cicd.sh` | Ver commit |
| disruptive-dev eliminado de workflows activos | ✅ |

### Próximo paso exacto

1. Merge PR → `develop`.
2. Configurar variables GitHub + environment `production`.
3. Autorizar `optimia-build-staging` tag `staging-cw-4.10.1-optimia-0.2.0`.
4. Deploy staging EasyPanel por digest (humano).
5. Smoke tests → aprobar build producción.

---

<!-- Próximas entradas se agregan debajo, sin modificar las anteriores -->
