# Matriz de riesgos — Technical Health Center v0.2.0

| Componente | Estado | Riesgo | Prioridad | Impacto | Evidencia | Recomendación |
|------------|--------|--------|-----------|---------|-----------|---------------|
| Rails / Puma | Implementado | Medio | P2 | Degradación UI/API | `RailsChecker`; migraciones pendientes → degraded | Ejecutar migración antes de deploy; monitorear `/internal/health` |
| Sidekiq | Operativo prod | Medio | P1 | Jobs detenidos, mensajes sin enviar | `SidekiqChecker`; alerta `sidekiq_stopped` | Verificar worker en EasyPanel tras cada deploy |
| Redis | Operativo prod | Alto | P1 | Caída total de colas y ActionCable | `RedisChecker`; alerta `redis_down` | Backup Redis; alertas externas vía token API |
| PostgreSQL | Operativo prod | Medio | P1 | Pérdida de datos / lentitud | `PostgresChecker`; umbral 500 ms | Monitorear latencia; plan backup (`backup-runbook.md`) |
| Evolution API | Integrado | Alto | P1 | WhatsApp inoperativo | `EvolutionChecker`; alerta `evolution_down` | Validar en staging; documentar versión pinneada |
| WhatsApp | Implementado | Alto | P1 | Clientes sin canal de mensajería | `WhatsappChecker`; alertas QR/errores | QA staging con Evolution; runbook conexiones |
| Webhooks | Implementado | Medio | P2 | Mensajes no entregados a Chatwoot | `WebhooksChecker`; alerta `webhook_broken` | Revisar `OPTIMIA_CHATWOOT_PUBLIC_URL`; re-provisionar inbox |
| Docker / Swarm | Parcial | Medio | P3 | Visibilidad limitada de infra | `DockerChecker` solo ENV; sin API Swarm | Configurar `OPTIMIA_SWARM_SERVICE` en EasyPanel |
| EasyPanel | Sin integración | Bajo | P3 | Sin visibilidad de panel | No hay checker de EasyPanel | Inventario manual periódico (`easypanel-production-checklist.md`) |
| Jobs / Scheduler | Implementado | Medio | P2 | Backlog, retries acumulados | `JobsChecker`; alertas backlog/retry | Revisar dead set en Sidekiq UI; escalar worker si backlog > 5000 |
| Deploy | Implementado | Medio | P2 | Versión incorrecta en prod | `DeployChecker`; `OptimiaDeploymentRecord` | Registrar deploy con `DeploymentCenterService.register!` |
| Storage | Implementado | Alto | P1 | Disco lleno → caída app | `StorageChecker`; alerta `storage_full` ≥ 90% | Alertar antes de 75%; limpiar adjuntos/logs |
| API interna | Implementado | Medio | P2 | Exposición si token débil | `HealthAuthentication`; token opcional | Generar token fuerte; rotar periódicamente |
| Staging | No desplegado | Alto | P1 | Sin validación pre-prod | Sprint 1 docs; sin entorno activo | Crear staging EasyPanel antes de promover v0.2.0 |
| Migración BD | Pendiente deploy | Medio | P1 | Tablas THC inexistentes en prod | `20260724160000_create_optimia_technical_health_tables` | Ejecutar migración en staging primero |
| Seguridad payloads | Implementado | Bajo | P3 | Fuga de datos sensibles | `Sanitizer` filtra tokens, teléfonos, QR | Auditar nuevos campos metadata al extender checkers |

## Leyenda

| Campo | Valores |
|-------|---------|
| **Prioridad** | P1 = inmediata, P2 = corto plazo, P3 = mejora |
| **Riesgo** | Alto / Medio / Bajo |
| **Impacto** | Efecto en clientes o operación |

## Resumen por prioridad

- **P1 (5):** Redis, Evolution, WhatsApp, Storage, Staging/migración.
- **P2 (5):** Sidekiq, Webhooks, Jobs, Deploy, API interna.
- **P3 (3):** Docker/Swarm metadatos, EasyPanel, Sanitizer.
