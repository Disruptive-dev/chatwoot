# Matriz de versiones Chatwoot — OptimiA

## Versiones conocidas

| Chatwoot base | Tag upstream | Commit upstream | OptimiA | Imagen | Estado |
|---------------|-------------|-----------------|---------|--------|--------|
| 4.10.1 | `v4.10.1` | `1345f679` | 0.1.2 | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` | **Activo (develop)** |
| 4.10.1 | — | `6a7cbcf5` | — | — | **Baseline fork** (`chatwoot-base/v4.10.1`) |

### Nota sobre dualidad 4.10.1

El fork divergió en `6a7cbcf5` (merge-base), que ya tenía `package.json` 4.10.1. El tag release upstream `v4.10.1` (`1345f679`) es un commit diferente y **no es ancestro** de `develop`.

## Versiones upstream disponibles (fetch Sprint 0)

| Tag | Notas |
|-----|-------|
| `v4.10.1` | Base actual declarada |
| `v4.11.1`, `v4.11.2` | Minor releases |
| `v4.12.0`, `v4.12.1` | Target de rama `fix/optimia-whitelabel-v4-12-1` |
| `v4.13.0` | |
| `v4.14.0`, `v4.14.1`, `v4.14.2` | |
| `v4.15.0`, `v4.15.1` | |
| `v4.16.0`, `v4.16.1` | Más reciente al momento del fetch |

`upstream/develop` HEAD: `a98666030` (713 commits adelante del fork).

## Desfase actual

```
chatwoot-base/v4.10.1 (6a7cbcf5)
    │
    ├── 43 commits OptimiA ──► develop (462802c9e)
    │
    └── 713 commits upstream ──► upstream/develop (a98666030)
```

## Plan de upgrade sugerido (futuro)

| Fase | Target Chatwoot | OptimiA bump | Sprint estimado |
|------|-----------------|--------------|-----------------|
| Actual | 4.10.1 | 0.1.2 | Sprint 0 ✅ |
| Upgrade 1 | 4.12.1 | 0.2.0 | Sprint 9 |
| Upgrade 2 | 4.14.x | 0.3.0 | TBD |
| Upgrade 3 | 4.16.x | 0.4.0 | TBD |

## Compatibilidad de migraciones

Antes de cada upgrade, verificar:

```bash
git diff v4.10.1..vX.Y.Z -- db/migrate/ | wc -l
```

Documentar migraciones nuevas y evaluar reversibilidad.

## Registro de upgrades (completar al ejecutar)

| Fecha | Desde | Hacia | OptimiA | Commit | Imagen | Resultado |
|-------|-------|-------|---------|--------|--------|-----------|
| — | — | — | — | — | — | Sprint 0: sin upgrade |

## Imágenes históricas GHCR

| Tag | Fecha aprox. | Commit |
|-----|--------------|--------|
| `v4.10.1-optimia.6` | 2026-07-16 | `462802c9e` |
| `v4.10.1-optimia.5` | 2026-07-16 | `8375c50c6` |
| `optimia-latest` | Flotante | Último build |

Namespace: `ghcr.io/disruptive-dev/chatwoot` (CI) y `ghcr.io/pablo-paez-dev/chatwoot` (histórico).
