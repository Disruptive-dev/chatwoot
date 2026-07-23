# Security Baseline — OptimiA (Sprint 0)

> Auditoría estática realizada el 2026-07-23. Sin acceso a producción ni secretos reales.

## Resumen

| Severidad | Cantidad |
|-----------|----------|
| Crítica | 0 (secretos versionados) |
| Alta | 3 |
| Media | 6 |
| Baja | 4 |
| Informativa | 3 |

**Bloqueo para producción:** No por secretos en repo, pero **sí por gaps de despliegue** (worker ausente en Dockerfile, usuario root, trazabilidad EasyPanel no verificada).

---

## Hallazgos

### SEC-001 — Contenedor ejecuta como root

| Campo | Valor |
|-------|-------|
| **Severidad** | Alta |
| **Evidencia** | `Dockerfile` líneas 1–53: sin directiva `USER` |
| **Impacto** | Escalación de privilegios si hay RCE en la aplicación |
| **Corrección** | Docker v2 con usuario non-root (ver `architecture/docker-v2-rfc.md`) |
| **Estado** | Abierto |
| **Bloquea prod** | Recomendado corregir antes de escalar |

### SEC-002 — Dockerfile sin HEALTHCHECK

| Campo | Valor |
|-------|-------|
| **Severidad** | Media |
| **Evidencia** | `Dockerfile`: ausencia de `HEALTHCHECK` |
| **Impacto** | Orquestador no detecta contenedor unhealthy; tráfico a instancia caída |
| **Corrección** | Añadir `HEALTHCHECK` apuntando a `/health` |
| **Estado** | Abierto |

### SEC-003 — Servicio Sidekiq ausente en imagen productiva

| Campo | Valor |
|-------|-------|
| **Severidad** | Alta |
| **Evidencia** | `Dockerfile` línea 53: solo `rails server` |
| **Impacto** | Si EasyPanel despliega solo este contenedor, jobs async no procesan |
| **Corrección** | Servicio worker separado con mismo tag; Docker v2 |
| **Estado** | Abierto |
| **Bloquea prod** | Sí, si worker no existe como servicio separado |

### SEC-004 — Default password en database.yml

| Campo | Valor |
|-------|-------|
| **Severidad** | Media |
| **Evidencia** | `config/database.yml` línea 31: `ENV.fetch('POSTGRES_PASSWORD', 'chatwoot_prod')` |
| **Impacto** | Si ENV no se configura, usa password predecible |
| **Corrección** | Eliminar fallback en producción; fallar si ENV ausente |
| **Estado** | Abierto (upstream Chatwoot) |

### SEC-005 — FRONTEND_URL hardcodeado en CI

| Campo | Valor |
|-------|-------|
| **Severidad** | Baja |
| **Evidencia** | `.github/workflows/build-optimia-chatwoot.yml` línea 41 |
| **Impacto** | URL de producción baked en assets; dificulta staging/multi-tenant |
| **Corrección** | Parametrizar por environment en workflow |
| **Estado** | Abierto |

### SEC-006 — Tag flotante `:optimia-latest`

| Campo | Valor |
|-------|-------|
| **Severidad** | Media |
| **Evidencia** | `build-optimia-chatwoot.yml` línea 38 |
| **Impacto** | Deploy no reproducible; rollback ambiguo |
| **Corrección** | Prohibir `:latest` en prod; solo tags inmutables |
| **Estado** | Abierto |

### SEC-007 — ActionCable CSRF deshabilitado

| Campo | Valor |
|-------|-------|
| **Severidad** | Informativa |
| **Evidencia** | `config/initializers/cors.rb` línea 35 |
| **Impacto** | Comportamiento estándar Chatwoot; riesgo conocido upstream |
| **Corrección** | Documentar; evaluar en hardening futuro |
| **Estado** | Aceptado (upstream) |

### SEC-008 — CORS permisivo en assets

| Campo | Valor |
|-------|-------|
| **Severidad** | Baja |
| **Evidencia** | `config/initializers/cors.rb` línea 8: `origins '*'` para `/packs/*` |
| **Impacto** | Estándar Chatwoot para assets estáticos |
| **Corrección** | Ninguna inmediata |
| **Estado** | Aceptado (upstream) |

### SEC-009 — Dependencias JS vulnerables

| Campo | Valor |
|-------|-------|
| **Severidad** | Alta |
| **Evidencia** | `pnpm audit`: 129 vulnerabilidades (2 critical, 57 high, 61 moderate, 9 low) |
| **Impacto** | Riesgo de explotación en frontend (ej. DOMPurify prototype pollution) |
| **Corrección** | `pnpm audit fix` + upgrade controlado en sprint de seguridad |
| **Estado** | Abierto — requiere evaluación de breaking changes |

### SEC-010 — bundle audit no ejecutado

| Campo | Valor |
|-------|-------|
| **Severidad** | Media |
| **Evidencia** | Ruby no disponible en entorno de auditoría; `bundle-audit` no instalado |
| **Impacto** | Vulnerabilidades Ruby gems no evaluadas |
| **Corrección** | Ejecutar `bundle audit` en CI con Ruby 3.4.4 |
| **Estado** | Pendiente |

### SEC-011 — gitleaks no ejecutado

| Campo | Valor |
|-------|-------|
| **Severidad** | Media |
| **Evidencia** | Herramienta no instalada en entorno de auditoría |
| **Impacto** | Secretos en historial git no escaneados automáticamente |
| **Corrección** | Integrar gitleaks en CI |
| **Estado** | Pendiente — búsqueda manual no encontró patrones obvios |

### SEC-012 — SECRET_KEY_BASE dummy en build args

| Campo | Valor |
|-------|-------|
| **Severidad** | Informativa |
| **Evidencia** | `build-optimia-chatwoot.yml` línea 40: `dummy_secret_key_base_for_assets` |
| **Impacto** | Aceptable para precompilación; runtime debe usar secret real vía ENV |
| **Corrección** | Verificar que prod tiene `SECRET_KEY_BASE` real configurado |
| **Estado** | Aceptado si runtime correcto |

### SEC-013 — Logs Spectra no exponen tokens

| Campo | Valor |
|-------|-------|
| **Severidad** | Informativa (positivo) |
| **Evidencia** | `lib/integrations/spectra_flow/client.rb`: `safe_config_sources` omite valores de token; solo reporta `token_configured: true/false` |
| **Impacto** | Buena práctica |
| **Corrección** | Mantener en futuras extensiones |
| **Estado** | OK |

### SEC-014 — Sin archivos .env versionados

| Campo | Valor |
|-------|-------|
| **Severidad** | Positivo |
| **Evidencia** | Solo `.env.example` presente; sin `.env` real en working tree |
| **Impacto** | Sin exposición de secretos en repo |
| **Estado** | OK |

### SEC-015 — Workflow permissions

| Campo | Valor |
|-------|-------|
| **Severidad** | Baja |
| **Evidencia** | `build-optimia-chatwoot.yml`: `contents: read`, `packages: write` |
| **Impacto** | Principio de mínimo privilegio adecuado |
| **Estado** | OK |

---

## Controles ejecutados

| Control | Herramienta | Resultado |
|---------|-------------|-----------|
| Archivos `.env` versionados | `find` | ✅ Ninguno |
| Patrones secretos (AKIA, ghp_, sk-) | `rg` | ✅ Ninguno en código app |
| Dependencias JS | `pnpm audit` | ⚠️ 129 vulnerabilidades |
| Dependencias Ruby | `bundle audit` | ⏳ Pendiente (Ruby no disponible) |
| Secretos en historial | `gitleaks` | ⏳ Pendiente (no instalado) |
| Dockerfile usuario root | Revisión manual | ⚠️ Confirmado |
| Workflow YAML | `python3 yaml` | ✅ 16/16 válidos |
| Logs Spectra tokens | Revisión manual | ✅ No expone valores |
| Archivos sensibles (.pem, .key) | `find` | ✅ Solo `config/rds-ca-2019-root.pem` (CA pública AWS) |

---

## Recomendaciones prioritarias

1. Verificar worker Sidekiq en EasyPanel (SEC-003).
2. Implementar Docker v2 con usuario non-root (SEC-001).
3. Ejecutar `bundle audit` en CI (SEC-010).
4. Integrar gitleaks en CI (SEC-011).
5. Planificar remediación de vulnerabilidades JS (SEC-009).
6. Eliminar `:optimia-latest` de producción (SEC-006).
