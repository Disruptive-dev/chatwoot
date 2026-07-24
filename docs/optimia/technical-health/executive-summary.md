# Resumen ejecutivo — Technical Health Center v0.2.0

**Sprint 3 · OptimiA 0.2.0 · Julio 2026**

## Objetivo

Entregar un centro de salud técnica integrado que permita monitorear, diagnosticar y operar la plataforma OptimiA sin acceso SSH, consolidando infraestructura, jobs, Evolution, WhatsApp y despliegues en una única vista de Super Admin.

## Entregables — checklist

| # | Entregable | Estado |
|---|------------|--------|
| 1 | NOC Dashboard (12 componentes) | ✅ |
| 2 | Orchestrator + 12 checkers | ✅ |
| 3 | Alert Detector (11 reglas) + incidentes | ✅ |
| 4 | Diagnostic Center (score + recomendaciones) | ✅ |
| 5 | Connection Monitor + Timeline | ✅ |
| 6 | Deployment Center + registro de versiones | ✅ |
| 7 | API interna `/internal/health/*` | ✅ |
| 8 | Job programado cada 5 min | ✅ |
| 9 | Migración BD (6 tablas) | ✅ |
| 10 | UI Super Admin + navegación | ✅ |
| 11 | Sanitización de payloads sensibles | ✅ |
| 12 | Specs RSpec (servicios, controllers, job) | ✅ |
| 13 | Documentación `docs/optimia/technical-health/` | ✅ |
| 14 | Versión OptimiA → 0.2.0 | ✅ |

## Alcance incluido

- Monitoreo de Rails, Puma (vía Rails), Sidekiq, Redis, PostgreSQL, Evolution, Docker/Swarm (metadatos), Storage, Jobs, Scheduler, Webhooks, WhatsApp y Deploy.
- Alertas automáticas con ciclo acknowledge/resolve.
- Incidentes derivados de alertas.
- Métricas históricas (`OptimiaTechnicalMetricSnapshot`).
- Integración con Channel Manager (Sprint 2) para conexiones WhatsApp.
- API JSON autenticada para integración con herramientas externas.

## Exclusiones de alcance

| Exclusión | Motivo |
|-----------|--------|
| Deploy a producción | Prohibido sin aprobación explícita |
| Deploy a staging | Pendiente acción humana EasyPanel |
| Integración API EasyPanel/Docker Swarm | Solo metadatos ENV en v0.2.0 |
| Monitoreo HTTP de webhooks (reachability) | Solo validación de configuración |
| Monitoreo S3/R2 externo | Solo disco local + tamaño BD |
| Auto-remediación | Fuera de MVP; solo alertas y runbooks |
| Notificaciones externas (email/Slack/PagerDuty) | Futuro sprint |
| Traducciones fuera de `en.yml` | Política del proyecto |
| ADR formal para Technical Health | No solicitado en Sprint 3 |

## Estado de producción

| Campo | Valor |
|-------|-------|
| Imagen actual | `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` |
| Versión OptimiA prod | 0.1.x (sin Technical Health Center) |
| v0.2.0 | Código listo; requiere migración + deploy staging |

## Riesgos principales

1. **Staging no desplegado** — sin validación end-to-end.
2. **Migración BD pendiente** — tablas THC no existen hasta deploy.
3. **Evolution externo** — dependencia crítica para WhatsApp.
4. **Docker checker limitado** — sin visibilidad real de Swarm.

Ver detalle en [risk-matrix.md](risk-matrix.md).

## Próximos pasos

| # | Acción | Responsable |
|---|--------|-------------|
| 1 | Merge rama `cursor/technical-health-center-3da0` → `develop` | Dev |
| 2 | Build imagen staging `staging-cw-4.10.1-optimia-0.2.0` | CI manual |
| 3 | Crear/actualizar staging en EasyPanel | Operador |
| 4 | Ejecutar migración BD en staging | Operador |
| 5 | Configurar `OPTIMIA_INTERNAL_HEALTH_TOKEN` y ENV deploy | Operador |
| 6 | Smoke tests Technical Health + Connection Center | QA |
| 7 | Completar QA staging antes de planificar prod | Producto |

## Documentación generada

- [README.md](README.md) — referencia técnica
- [audit.md](audit.md) — auditoría por componente
- [risk-matrix.md](risk-matrix.md) — matriz de riesgos
- [runbooks.md](runbooks.md) — procedimientos operativos
- [executive-summary.md](executive-summary.md) — este documento

## Deploy

**No realizado** en Sprint 3 (por diseño).
