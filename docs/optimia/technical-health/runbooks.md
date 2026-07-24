# Runbooks operativos — Technical Health Center v0.2.0

Procedimientos sin SSH. Todas las acciones se ejecutan desde Super Admin, EasyPanel o API interna.

---

## RB-01 — Acceder al dashboard

1. Iniciar sesión como **Super Admin** en `https://app.optimia.spectra-metrics.com/super_admin`.
2. Sidebar → **Technical Health**.
3. Verificar estado de los 12 componentes (semáforo 🟢🟡🔴⚪).

**Criterio OK:** Mayoría en `healthy`; sin alertas `critical` abiertas.

---

## RB-02 — Refrescar checks manualmente

1. Super Admin → Technical Health.
2. Clic en **Refresh checks**.
3. Confirmar mensaje *Technical health checks refreshed*.

Alternativa programada: job `CollectHealthJob` cada 5 minutos (requiere Sidekiq worker activo).

---

## RB-03 — Consultar salud vía API (sin UI)

```bash
curl -s -H "Authorization: Bearer $OPTIMIA_INTERNAL_HEALTH_TOKEN" \
  https://app.optimia.spectra-metrics.com/internal/health | jq .
```

Endpoints por componente: `/internal/health/redis`, `/postgres`, `/evolution`, `/webhooks`, `/sidekiq`, `/storage`.

**Prerrequisito:** Variable `OPTIMIA_INTERNAL_HEALTH_TOKEN` configurada en EasyPanel (web + worker).

---

## RB-04 — Alerta: Sidekiq detenido

**Síntoma:** Componente `sidekiq` en 🔴; alerta `sidekiq_stopped`.

1. Super Admin → Technical Health → verificar `sidekiq` = critical.
2. EasyPanel → servicio `chatwoot-sidekiq` → verificar estado **Running**.
3. Si detenido: **Restart** del servicio worker (no tocar web ni BD).
4. Super Admin → **Refresh checks**.
5. Opcional: `/monitoring/sidekiq` → confirmar procesos activos.

**Escalación:** Si no arranca tras restart, revisar logs del worker en EasyPanel.

---

## RB-05 — Alerta: Redis caído

**Síntoma:** `redis` = critical; alerta `redis_down`.

1. EasyPanel → servicio `chatwoot-redis` → verificar Running.
2. Si detenido: Restart redis, luego restart `chatwoot-sidekiq`.
3. Refresh checks en Technical Health.

**Impacto:** Colas, sesiones y ActionCable afectados hasta recuperación.

---

## RB-06 — Alerta: Evolution API no disponible

**Síntoma:** `evolution` = critical; alerta `evolution_down`.

1. Technical Health → verificar latencia y metadata del checker.
2. EasyPanel → verificar servicio Evolution (si aplica) o endpoint externo.
3. Confirmar ENV en web/worker: `EVOLUTION_API_URL`, `EVOLUTION_API_KEY`.
4. Tras recuperación: Refresh checks; verificar conexiones WhatsApp.

---

## RB-07 — Alerta: Webhook roto

**Síntoma:** `webhooks` = degraded/critical; alerta `webhook_broken`.

1. Technical Health → tabla WhatsApp Connections.
2. Identificar conexión afectada → **Diagnose**.
3. Verificar `OPTIMIA_CHATWOOT_PUBLIC_URL` en EasyPanel.
4. Configuración → WhatsApp → reconectar o re-provisionar inbox.
5. Refresh checks; confirmar `webhook_configured: true` en diagnose.

---

## RB-08 — Alerta: QR expirado

**Síntoma:** Alerta `qr_expired`; conexiones en estado `waiting_qr`.

1. Technical Health → conexión afectada → **Timeline** (historial de eventos).
2. Configuración → WhatsApp → escanear nuevo QR.
3. Esperar transición a `connected`/`ready`.
4. Acknowledge alerta si resuelto.

---

## RB-09 — Alerta: Backlog de jobs alto

**Síntoma:** `jobs` = degraded; alertas `pending_messages` o `excessive_retries`.

1. Technical Health → revisar métricas backlog/retry en dashboard.
2. Super Admin → `/monitoring/sidekiq` → identificar cola congestionada.
3. Si transitorio: esperar 15 min y refresh.
4. Si persistente: escalar réplicas worker en EasyPanel o investigar job fallido en Retry/Dead.

---

## RB-10 — Alerta: Storage crítico

**Síntoma:** `storage` = critical; alerta `storage_full` (≥ 90%).

1. Technical Health → ver `disk_used_percent` y `database_size_mb`.
2. EasyPanel → revisar volumen del servicio web.
3. Ejecutar limpieza según `docs/optimia/operations/backup-runbook.md`.
4. Planificar expansión de disco si ≥ 75% sostenido.

---

## RB-11 — Diagnóstico de plataforma

1. Technical Health → **Run platform diagnostic**.
2. Revisar score (0–100) y lista de recomendaciones.
3. Para JSON: `GET /super_admin/technical_health/diagnose.json` (sesión super_admin).

**Score < 70:** Revisar componentes en recomendaciones antes de operar en prod.

---

## RB-12 — Diagnóstico de conexión WhatsApp

1. Technical Health → tabla conexiones → **Diagnose** en la fila deseada.
2. Revisar score, checks parciales y estado de conexión.
3. Si score bajo: seguir RB-06, RB-07 u RB-08 según recomendación.

Timeline: **Timeline** en la misma fila para ver secuencia de eventos.

---

## RB-13 — Gestión de alertas e incidentes

### Reconocer alerta
1. Technical Health → sección Alerts.
2. **Acknowledge** en la alerta correspondiente.

### Resolver alerta
1. Tras corregir causa raíz → **Resolve**.

### Incidentes
1. Se crean automáticamente desde alertas críticas.
2. **Acknowledge** → asignar responsable.
3. **Resolve** → documentar `root_cause` y `action_taken`.

---

## RB-14 — Deploy de v0.2.0 (staging, sin prod)

1. GitHub Actions → `Build Optimia Chatwoot Staging Image` (manual).
2. EasyPanel staging → actualizar imagen a `staging-cw-4.10.1-optimia-0.2.0`.
3. Ejecutar migraciones (arranque web o release command).
4. Configurar ENV Technical Health (token, deploy metadata).
5. Super Admin staging → Technical Health → Refresh checks.
6. Validar los 12 componentes y smoke tests Channel Manager.

**Prohibido:** Aplicar en producción sin QA staging completo.

---

## RB-15 — Verificar scheduler (Sidekiq-Cron)

1. Technical Health → componente `scheduler`.
2. Confirmar `enabled_jobs` > 0 y presencia de `optimia_technical_health_collect_job`.
3. Si degraded: verificar worker Sidekiq y archivo `config/schedule.yml` en imagen desplegada.

---

## Contactos y escalación

| Nivel | Acción |
|-------|--------|
| L1 | Operador revisa Technical Health + EasyPanel restart |
| L2 | DevOps revisa logs EasyPanel, ENV, migraciones |
| L3 | Desarrollo revisa checkers, Evolution, Channel Manager |

Documentación complementaria:
- `docs/optimia/operations/staging-connection-center-runbook.md`
- `docs/optimia/operations/deployment-runbook.md`
- `docs/optimia/operations/rollback-runbook.md`
