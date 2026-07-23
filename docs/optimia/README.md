# OptimiA — Documentación técnica

Este directorio contiene la documentación operativa, arquitectónica y de seguridad de **OptimiA**, producto basado en Chatwoot mantenido por Disruptive SW / DSW-Factory.

## Alcance

- **Sprint 0** (actual): trazabilidad, baseline, seguridad y preparación del repositorio.
- Sin cambios funcionales, visuales ni de base de datos en este sprint.

## Estructura

| Directorio | Contenido |
|------------|-----------|
| [`architecture/`](architecture/) | Estado actual, estado objetivo, topología de despliegue, RFC Docker v2 |
| [`operations/`](operations/) | Runbooks de backup, deploy, rollback; plantilla EasyPanel |
| [`security/`](security/) | Baseline de seguridad y gestión de secretos |
| [`upgrades/`](upgrades/) | Estrategia upstream y matriz de versiones Chatwoot |
| [`inventory/`](inventory/) | Personalizaciones, archivos críticos, variables de entorno |
| [`adr/`](adr/) | Architecture Decision Records |

## Versiones de referencia (Sprint 0)

| Componente | Versión |
|------------|---------|
| Chatwoot base | 4.10.1 |
| OptimiA | 0.1.2 |
| Commit HEAD | `462802c9e` |
| Tag baseline | `chatwoot-base/v4.10.1` → `6a7cbcf5` |
| Imagen CI | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |

## Próximos pasos

1. Completar inventario manual en EasyPanel (`operations/easypanel-inventory-template.md`).
2. Aprobar ADR-001 (repositorio canónico).
3. Implementar Docker v2 (ver `architecture/docker-v2-rfc.md`).
4. Sprint 1: normalización de repositorio y CI en DSW-Factory.
