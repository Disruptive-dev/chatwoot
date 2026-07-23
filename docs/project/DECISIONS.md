# DECISIONS — OptimiA

> Registro de decisiones técnicas y de producto. Append-only.

## Formato

```
### DEC-NNN — Título
- Fecha:
- Estado: PROPUESTA | APROBADA | RECHAZADA | SUPERSEDIDA
- Contexto:
- Decisión:
- Consecuencias:
```

---

## Decisiones registradas

### DEC-001 — Baseline del fork en `6a7cbcf5`

- **Fecha:** 2026-07-23
- **Estado:** APROBADA (Sprint 0)
- **Contexto:** El tag upstream `v4.10.1` (`1345f679`) no es ancestro de `develop`. El fork divergió en `6a7cbcf5`, último commit antes de `ac4ec0fbe` (primer cambio OptimiA).
- **Decisión:** Tag `chatwoot-base/v4.10.1` apunta a `6a7cbcf5`, no a `1345f679`.
- **Consecuencias:** Upgrades futuros deben usar este baseline como punto de partida para rebases/cherry-picks.

### DEC-002 — No asumir imagen CI como producción

- **Fecha:** 2026-07-23
- **Estado:** APROBADA (Sprint 0)
- **Contexto:** CI publica `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` pero no hay configuración EasyPanel en el repo.
- **Decisión:** La imagen CI se documenta como "detectada", no como "desplegada", hasta verificación manual.
- **Consecuencias:** Sprint 1 bloqueado hasta checklist EasyPanel completado por el usuario.

### DEC-003 — Protocolo de continuidad cross-session

- **Fecha:** 2026-07-23
- **Estado:** APROBADA (cierre Sprint 0)
- **Contexto:** Trabajo distribuido entre Cursor Online, Desktop, Coder y GitHub.
- **Decisión:** `docs/project/` + `scripts/project-context.sh` + regla Cursor como fuente de verdad compartida.
- **Consecuencias:** Todo agente debe leer estado y ejecutar diagnóstico Git antes de modificar código.

---

## ADRs (propuestas — pendiente decisión propietario)

| ADR | Tema | Estado |
|-----|------|--------|
| [ADR-001](../optimia/adr/ADR-001-canonical-repository.md) | Repositorio canónico `DSW-Factory/optimia-chatwoot` | PROPUESTA |
| [ADR-002](../optimia/adr/ADR-002-container-strategy.md) | Docker v2 web + worker | PROPUESTA |
| [ADR-003](../optimia/adr/ADR-003-versioning-strategy.md) | Versionado SemVer OptimiA | PROPUESTA |

No aprobar ni implementar ADRs hasta decisión explícita del propietario.
