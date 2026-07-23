# ADR-001: Repositorio canónico OptimiA

| Campo | Valor |
|-------|-------|
| Estado | **PROPUESTA — PENDIENTE DE APROBACIÓN** |
| Fecha | 2026-07-23 |
| Decisores | Equipo OptimiA / DSW-Factory |

## Estado de aprobación

**PENDIENTE DE DECISIÓN DEL PROPIETARIO**

No crear ni transferir `DSW-Factory/optimia-chatwoot` hasta aprobación explícita.

## Contexto

OptimiA se desarrolla actualmente en `pablo-paez-dev/chatwoot`, una cuenta personal de GitHub. El CI publica imágenes en `ghcr.io/disruptive-dev/chatwoot` bajo la org Disruptive-dev. Existe la org `DSW-Factory` en GitHub sin repositorio `chatwoot`/`optimia-chatwoot` aún.

Problemas detectados:
- Producto empresarial en cuenta personal.
- Ambigüedad de ownership (personal vs org).
- Sin branch protection governance centralizada.
- Imágenes GHCR en múltiples namespaces (`disruptive-dev`, `pablo-paez-dev`).
- Dificultad para onboarding de equipo y auditoría.

## Decisión propuesta

Migrar el repositorio canónico a:

```
DSW-Factory/optimia-chatwoot
```

## Justificación

| Criterio | Cuenta personal | DSW-Factory org |
|----------|----------------|-----------------|
| Governance | Limitada | Branch protection, teams, CODEOWNERS |
| CI/CD secrets | Personales | Org-level secrets |
| GHCR | Namespace personal | `ghcr.io/dsw-factory/optimia-chatwoot` |
| Auditoría | Difícil | Trazable |
| Continuidad | Depende de individuo | Org ownership |
| Licencia MIT | Compatible | Compatible (fork Chatwoot) |

## Plan de migración (sin romper producción)

### Fase A — Preparación (Sprint 0–1)

1. Completar documentación baseline (este sprint).
2. Verificar trazabilidad EasyPanel → imagen actual.
3. Backup completo prod.
4. Crear `DSW-Factory/optimia-chatwoot` como repo vacío o mirror.

### Fase B — Espejo (sin cambiar prod)

1. Push mirror completo con todas las ramas y tags:
   ```bash
   git push --mirror git@github.com:DSW-Factory/optimia-chatwoot.git
   ```
2. Configurar branch protection en `main` y `develop`.
3. Replicar workflows CI apuntando a nuevo GHCR.
4. **No cambiar** EasyPanel todavía.

### Fase C — Transición CI

1. Nuevo workflow publica a `ghcr.io/dsw-factory/optimia-chatwoot`.
2. Mantener publicación paralela en `disruptive-dev` por 1–2 releases.
3. Validar imagen nueva en staging.

### Fase D — Transición deploy

1. Actualizar EasyPanel para pull desde nuevo GHCR.
2. Verificar smoke tests.
3. Marcar `pablo-paez-dev/chatwoot` como archived/redirect.
4. Actualizar `origin` local de desarrolladores.

### Fase E — Limpieza

1. Deprecar imágenes antiguas en GHCR (retención 90 días).
2. Archivar repo personal.
3. Actualizar documentación y ADRs.

## Preservación de historial

- Usar `git push --mirror` para preservar ramas, tags y commits.
- Tag `chatwoot-base/v4.10.1` ya creado en Sprint 0.
- No reescribir historial (no force push).

## Compatibilidad temporal con imágenes anteriores

| Período | Imagen activa | Imagen legacy |
|---------|---------------|---------------|
| Transición | `ghcr.io/dsw-factory/optimia-chatwoot:<tag>` | `ghcr.io/disruptive-dev/chatwoot:<tag>` |
| Post-transición (+90d) | Solo DSW-Factory | Deprecada |

EasyPanel puede mantener tag anterior hasta validar nuevo registry.

## Verificaciones pre-transferencia

- [ ] Inventario EasyPanel completado
- [ ] Backup prod verificado
- [ ] CI funcional en nuevo repo
- [ ] Imagen staging desplegada y testeada
- [ ] Permisos org DSW-Factory configurados
- [ ] Secrets migrados a org secrets
- [ ] DNS/TLS no afectados (solo cambia imagen source)

## Permisos y protección de ramas

| Rama | Protección |
|------|------------|
| `main` | Require PR, 1 review, CI green, no force push |
| `develop` | Require PR, CI green |
| `release/*` | Require PR |
| Tags `optimia/v*` | Solo via CI o maintainers |

## Consecuencias

### Positivas
- Ownership claro del producto.
- CI/CD centralizado.
- GHCR unificado.
- Mejor auditoría.

### Negativas
- Esfuerzo de migración (~1 sprint).
- Período de dual-publish de imágenes.
- Actualizar referencias en docs/CI/EasyPanel.

## Alternativas consideradas

| Alternativa | Descartada porque |
|-------------|-------------------|
| Mantener en cuenta personal | Sin governance empresarial |
| Solo renombrar repo personal | No resuelve ownership org |
| Monorepo con otros productos DSW | OptimiA es deployable independiente |

## Estado

```
PROPUESTA — PENDIENTE DE APROBACIÓN
```

No se ha creado ni transferido ningún repositorio en Sprint 0.
