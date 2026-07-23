# Inventario de personalizaciones — OptimiA

> Generado Sprint 0. Base de comparación: `upstream/develop` vs `develop` (111 archivos).

## Resumen por categoría

| # | Categoría | Archivos | Riesgo predominante |
|---|-----------|----------|---------------------|
| 1 | Branding | 6 + assets | Medio |
| 2 | Traducciones backend | 2 | **Alto** |
| 3 | Login i18n | 25 | Medio-Alto |
| 4 | Layouts | 1 | Medio |
| 5 | Spectra Flow | 12 | Medio |
| 6 | Comandos internos | 5 | Medio |
| 7 | CI/CD | 1 | Bajo |
| 8 | Docker | 1 | **Alto** |
| 9 | Rutas | 1 | Medio |
| 10 | Componentes core | 3 | **Alto** |
| 11 | Tests propios | 3 | Bajo |
| — | Widget/Survey i18n | 38 | Bajo |
| — | InboxMgmt i18n | 22 | Bajo |

---

## 1. Branding

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `public/brand-assets/logo.svg` | Logo principal OptimiA | `6752bce1d` | Bajo | Mantener (assets) |
| `public/brand-assets/logo_dark.svg` | Logo modo oscuro | `6752bce1d` | Bajo | Mantener |
| `public/brand-assets/logo_thumbnail.svg` | Thumbnail/favicon | `6752bce1d` | Bajo | Mantener |
| `app/javascript/shared/components/Branding.vue` | Footer "Powered by OptimIA" → `optimia.disruptive-sw.com` | `5a6d19633` | Bajo | Reemplazar por configuración |
| `public/manifest.json` | **No modificado** — sigue "Chatwoot" | — | Bajo | Actualizar en sprint branding |

---

## 2. Traducciones backend

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `config/locales/en.yml` | ~200 strings "OptimIA" en mensajes sistema | `06d418ed7` | **Alto** | Refactorizar — solo deltas, no archivo completo |
| `config/locales/es.yml` | ~200 strings "OptimIA" en mensajes sistema | `05b263e1c` | **Alto** | Refactorizar — solo deltas |

---

## 3. Login i18n (25 archivos)

Patrón: `"TITLE": "Login to OptimiA"` en `app/javascript/dashboard/i18n/locale/*/login.json`.

| Riesgo | Estrategia |
|--------|------------|
| Medio-Alto (volumen) | Reducir a `en/login.json` y `es/login.json` únicamente; revertir otros 23 |

---

## 4. Layouts

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `app/views/layouts/vueapp.html.erb` | Título OptimIA, meta description ES, favicon SVG, noscript ES | `95ccf9340` | Medio | Aislar cambios mínimos; usar ENV para título |

---

## 5. Integración Spectra Flow

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `lib/integrations/spectra_flow/client.rb` | Cliente HTTP Spectra (526 líneas) | `8375c50c6` | Medio | **Aislar** — mantener en `lib/integrations/` |
| `lib/integrations/spectra_flow/errors.rb` | Códigos de error | `0f08b309d` | Bajo | Mantener |
| `app/services/integrations/spectra_flow/documents_service.rb` | Servicio dominio | `0f08b309d` | Medio | Mantener |
| `app/controllers/api/v1/accounts/spectra/documents_controller.rb` | API REST documentos | `bd3c5fab5` | Medio | Mantener |
| `app/javascript/dashboard/api/spectra/documents.js` | Cliente API frontend | `0f08b309d` | Bajo | Mantener |
| `app/javascript/dashboard/components/widgets/conversation/internalCommands/DocumentCommandModal.vue` | Modal UI documentos | `bd3c5fab5` | Medio | Mantener |
| `lib/tasks/spectra_flow.rake` | Rake health check | `0f08b309d` | Bajo | Mantener |
| `spec/lib/integrations/spectra_flow/client_spec.rb` | Tests cliente | `0f08b309d` | Bajo | Mantener |
| `spec/requests/api/v1/accounts/spectra/documents_spec.rb` | Tests API | `bd3c5fab5` | Bajo | Mantener |
| `spec/services/integrations/spectra_flow/documents_service_spec.rb` | Tests servicio | `0f08b309d` | Bajo | Mantener |
| `app/javascript/dashboard/i18n/locale/en/conversation.json` | Strings Spectra EN | `bd3c5fab5` | Bajo | Mantener |
| `app/javascript/dashboard/i18n/locale/es/conversation.json` | Strings Spectra ES | `bd3c5fab5` | Bajo | Mantener |

---

## 6. Comandos internos

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `app/javascript/dashboard/helper/internalCommands/registry.js` | Registro `@documentos` (activo) + 6 planificados | `bd3c5fab5` | Medio | Mantener — extensible |
| `app/javascript/dashboard/helper/internalCommands/index.js` | Parser `@documentos` | `bd3c5fab5` | Medio | Mantener |
| `app/javascript/dashboard/helper/specs/internalCommands.spec.js` | Tests unitarios | `bd3c5fab5` | Bajo | Mantener |

Comandos planificados (no implementados): `@crm`, `@cliente`, `@playbook`, `@ia`, `@resumen`, `@cotizacion`.

---

## 7. CI/CD

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `.github/workflows/build-optimia-chatwoot.yml` | Build + push GHCR OptimiA | `d3a9aa9fa` / `462802c9e` | Medio | Refactorizar — mover a DSW-Factory, tags inmutables |

---

## 8. Docker

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `Dockerfile` (raíz) | Dockerfile custom single-stage, solo web | `5cb061efd` / `80efce016` | **Crítico** | **Reemplazar** por Docker v2 (RFC) |

---

## 9. Rutas

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `config/routes.rb` | Namespace `spectra/documents` (+9 líneas) | `bd3c5fab5` | Medio | Mantener — considerar engine mountable |

---

## 10. Componentes core modificados

| Archivo | Descripción | Commit origen | Riesgo | Estrategia |
|---------|-------------|---------------|--------|------------|
| `app/javascript/dashboard/App.vue` | `UpdateBanner` comentado/eliminado | `27104a2b7` | **Alto** | Revisar — usar `displayManifest` config en vez de comentar imports |
| `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue` | Integración `@documentos` + modal Spectra | `bd3c5fab5` | **Crítico** | Refactorizar — minimizar diff; hook/composable |
| `app/javascript/dashboard/components/widgets/WootWriter/Editor.vue` | Soporte comandos internos | `bd3c5fab5` | Medio | Revisar diff mínimo |

---

## 11. Tests propios

| Archivo | Tipo | Commit |
|---------|------|--------|
| `spec/lib/integrations/spectra_flow/client_spec.rb` | RSpec unitario | `0f08b309d` |
| `spec/requests/api/v1/accounts/spectra/documents_spec.rb` | RSpec request | `bd3c5fab5` |
| `spec/services/integrations/spectra_flow/documents_service_spec.rb` | RSpec service | `0f08b309d` |
| `app/javascript/dashboard/helper/specs/internalCommands.spec.js` | Vitest unitario | `bd3c5fab5` |

---

## Widget / Survey / InboxMgmt i18n (38 + 22 archivos)

Cambios menores en `POWERED_BY` y strings relacionados. Riesgo bajo individual, alto en volumen.

**Estrategia:** Revertir cambios en idiomas no soportados activamente; mantener solo `en` y `es`.

---

## Archivos críticos — atención especial

| Archivo | Nivel | Motivo |
|---------|-------|--------|
| `ReplyBox.vue` | **Crítico** | Archivo muy activo upstream; diff grande |
| `Dockerfile` | **Crítico** | Define despliegue incompleto |
| `config/locales/en.yml` | **Alto** | Conflictos masivos en upgrades |
| `config/locales/es.yml` | **Alto** | Conflictos masivos en upgrades |
| `App.vue` | **Alto** | Root component; cambio de imports |
| `config/routes.rb` | **Alto** | Archivo central de routing |
| `vueapp.html.erb` | **Medio** | Layout HTML principal |
| `build-optimia-chatwoot.yml` | **Medio** | Pipeline de release |
| `Branding.vue` | **Bajo** | Cambio acotado |

---

## Commits OptimiA (43 total, cronológico inverso)

```
462802c9e v4.10.1 - Optimia Inbox v0.1.2 — Publicar imagen corregida
8375c50c6 v4.10.1 - Optimia Inbox v0.1.2 — Adjuntar documentos desde Spectra
0f08b309d v4.10.1 - Optimia Inbox v0.1.1 — Conexión documental con Spectra
bd3c5fab5 v4.10.1 - Optimia Inbox v0.1.0 — Comando interno de documentos
13bdb33d7 Tag Optimia image according to current Chatwoot base version
27104a2b7 Hide update banner in Optimia white-label build
d3a9aa9fa Add GitHub Actions build for Optimia Chatwoot image
b6bd02a0f Restore Optimia white-label branding on Chatwoot 4.12.1
... (branding commits) ...
ac4ec0fbe Add files via upload  ← primer commit OptimiA (padre: 6a7cbcf5)
```
