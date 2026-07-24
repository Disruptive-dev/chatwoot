# OptimiA — Documentación técnica

Este directorio contiene la documentación operativa, arquitectónica y de seguridad de **OptimiA**, producto basado en Chatwoot mantenido por Disruptive SW / DSW-Factory.

## Alcance

- **Sprint 0** (actual): trazabilidad, baseline, seguridad y preparación del repositorio.
- Sin cambios funcionales, visuales ni de base de datos en este sprint.

## Estructura

| Directorio | Contenido |
|------------|-----------|
| [`architecture/`](architecture/) | Estado actual, estado objetivo, topología de despliegue, RFC Docker v2 |
| [`environments/`](environments/) | **Staging aislado** — arquitectura, variables, imágenes, controles |
| [`operations/`](operations/) | Runbooks de backup, deploy, rollback; guías EasyPanel |
| [`security/`](security/) | Baseline de seguridad y gestión de secretos |
| [`upgrades/`](upgrades/) | Estrategia upstream y matriz de versiones Chatwoot |
| [`inventory/`](inventory/) | Personalizaciones, archivos críticos, variables de entorno |
| [`adr/`](adr/) | Architecture Decision Records |
| [`technical-health/`](technical-health/) | **Technical Health Center v0.2.0** — NOC, auditoría, riesgos, runbooks |

## Versiones de referencia

| Componente | Versión |
|------------|---------|
| Chatwoot base | 4.10.1 |
| OptimiA | 0.2.0 |
| Imagen prod | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Imagen staging propuesta | `staging-cw-4.10.1-optimia-0.2.0` |
| Tag baseline | `chatwoot-base/v4.10.1` → `6a7cbcf5` |

## Próximos pasos

1. ~~Completar inventario manual en EasyPanel~~ — producción verificada Sprint 1.
2. Disparar workflow `build-optimia-chatwoot-staging.yml` (manual) con tag v0.2.0.
3. Crear proyecto staging en EasyPanel siguiendo [`operations/easypanel-staging-setup-guide.md`](operations/easypanel-staging-setup-guide.md).
4. QA Technical Health Center: [`technical-health/runbooks.md`](technical-health/runbooks.md).
5. Aprobar ADR-001, ADR-002, ADR-003.
6. Implementar Docker v2 (post-staging operativo).
