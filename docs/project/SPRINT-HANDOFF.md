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

<!-- Próximas entradas se agregan debajo, sin modificar las anteriores -->
