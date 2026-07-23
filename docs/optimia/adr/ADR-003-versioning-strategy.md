# ADR-003: Estrategia de versionado OptimiA

| Campo | Valor |
|-------|-------|
| Estado | **PROPUESTA — PENDIENTE DE APROBACIÓN** |
| Fecha | 2026-07-23 |

## Contexto

OptimiA tiene dos dimensiones de versión:
1. **Chatwoot base** — versión del upstream (actualmente 4.10.1).
2. **OptimiA** — versión del producto con personalizaciones propias (actualmente 0.1.2).

Hoy la imagen se publica como `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6`, mezclando ambas dimensiones sin SemVer claro de OptimiA.

## Decisión propuesta

### Dos versiones independientes

```
Chatwoot base:  4.10.1
OptimiA:        0.1.2
```

### Formato de imagen Docker

```
ghcr.io/dsw-factory/optimia-chatwoot:cw-4.10.1-optimia-0.1.2
```

Componentes:
- `cw-4.10.1` — versión Chatwoot base (pin upstream)
- `optimia-0.1.2` — versión SemVer del producto OptimiA

### Formato de tags Git

```
optimia/v0.1.2          → release OptimiA
chatwoot-base/v4.10.1   → baseline upstream (creado Sprint 0 → 6a7cbcf5)
```

### Mapeo commit ↔ tag ↔ imagen

```
Commit:  462802c9e
Tag git: optimia/v0.1.2 (futuro)
Imagen:  ghcr.io/dsw-factory/optimia-chatwoot:cw-4.10.1-optimia-0.1.2
```

## SemVer OptimiA

### Patch (0.1.x → 0.1.y)

- Bugfixes en código OptimiA (Spectra, comandos internos).
- Correcciones de seguridad en módulos propios.
- Ajustes de CI/CD o Dockerfile sin cambio funcional.
- Sin cambio de Chatwoot base.

### Minor (0.1.x → 0.2.0)

- Nueva funcionalidad OptimiA (nuevo comando `@ia`, integración Evolution).
- Nuevos endpoints API propios.
- Mejoras de branding significativas.
- Puede incluir upgrade menor de Chatwoot base.

### Major (0.x → 1.0.0)

- Cambio breaking en API OptimiA propia.
- Upgrade mayor de Chatwoot base con incompatibilidades.
- Rediseño arquitectónico (ej. migración a DSW-Factory completa).
- Primera release "producto estable" → 1.0.0.

## Registro de actualización Chatwoot

Cuando se actualiza la base Chatwoot:

1. Crear rama `upgrade/chatwoot-X.Y.Z`.
2. Merge/rebase upstream tag `vX.Y.Z`.
3. Resolver conflictos en archivos inventariados.
4. Actualizar `package.json` version.
5. Crear tag `chatwoot-base/vX.Y.Z` en el commit base post-merge.
6. Bump minor (o major) de OptimiA según impacto.
7. Publicar imagen: `cw-X.Y.Z-optimia-A.B.C`.

Documentar en `docs/optimia/upgrades/chatwoot-version-matrix.md`.

## Identificación de versión desplegada

| Método | Fuente |
|--------|--------|
| Tag imagen EasyPanel | Registro deploy |
| Digest SHA256 | `docker inspect` |
| Commit en imagen | Archivo `.git_sha` (Dockerfile oficial) o label OCI |
| Versión UI | Settings → About (si `displayManifest` habilitado) |
| Tag git | `optimia/vX.Y.Z` |

## Prohibiciones

| Práctica | Motivo |
|----------|--------|
| `:latest` en producción | Deploy no reproducible |
| `:optimia-latest` en producción | Tag flotante |
| Rebuild distinto staging vs prod | Misma imagen, mismo tag |
| Tag sin commit asociado | Pierde trazabilidad |

## Estado actual vs propuesto

| Aspecto | Actual | Propuesto |
|---------|--------|-----------|
| Imagen | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` | `ghcr.io/dsw-factory/optimia-chatwoot:cw-4.10.1-optimia-0.1.2` |
| Tag git OptimiA | No existe | `optimia/v0.1.2` |
| Tag git Chatwoot base | No existía | `chatwoot-base/v4.10.1` → `6a7cbcf5` ✅ |
| Contador optimia.N | `optimia.6` (opaco) | SemVer `0.1.2` |

## Nota sobre baseline tag

`chatwoot-base/v4.10.1` apunta a `6a7cbcf5` (merge-base con upstream), **no** al tag upstream `v4.10.1` (`1345f679`). Ambos tienen `package.json` en 4.10.1, pero son commits distintos. Ver [`current-state.md`](../architecture/current-state.md).

## Tags creados en Sprint 0

| Tag | Commit | Notas |
|-----|--------|-------|
| `chatwoot-base/v4.10.1` | `6a7cbcf5` | Último commit upstream antes de primer cambio OptimiA |

**No se crearon** tags `optimia/v*` en Sprint 0 (pendiente de aprobación de esta ADR).

## Estado

```
PROPUESTA — PENDIENTE DE APROBACIÓN
```
