# Estado actual — OptimiA (Sprint 0)

> Documento basado en verificación directa del repositorio el 2026-07-23. Solo hechos comprobados.

## Repositorio

| Campo | Valor verificado |
|-------|------------------|
| Ruta local | `/workspace` |
| Remoto `origin` | `https://github.com/pablo-paez-dev/chatwoot` |
| Remoto `upstream` | `https://github.com/chatwoot/chatwoot.git` (añadido en Sprint 0) |
| Rama activa | `develop` |
| Working tree | Limpio |
| Último commit | `462802c9ea09065452912e5a72116f93f4db483c` |
| Autor último commit | Pablo Paez (`pablo@disruptive-sw.com`) |
| Mensaje | `v4.10.1 - Optimia Inbox v0.1.2 — Publicar imagen corregida` |
| Fork de | `chatwoot/chatwoot` |
| Tags locales | 141 (upstream + `chatwoot-base/v4.10.1` creado en Sprint 0) |
| Releases GitHub | 0 |

### Ramas remotas

- `origin/develop` (default)
- `origin/backup-develop-antes-update`
- `origin/fix/optimia-whitelabel-v4-12-1`
- `origin/patch-1`, `origin/patch-2`

### Desfase respecto a upstream (`upstream/develop`)

| Métrica | Valor |
|---------|-------|
| Commits adelante | 43 |
| Commits detrás | 713 |
| Ancestro común (merge-base) | `6a7cbcf5` |
| Primer commit OptimiA | `ac4ec0fbe` (padre: `6a7cbcf5`) |

**Nota:** El tag upstream `v4.10.1` (`1345f679`) **no es ancestro** de `develop`. El baseline real del fork es `6a7cbcf5`, que ya tenía `package.json` en versión `4.10.1`.

## Versiones de runtime

| Componente | Versión |
|------------|---------|
| Chatwoot (`package.json`) | 4.10.1 |
| Ruby (`.ruby-version`) | 3.4.4 |
| Rails (`Gemfile`) | ~> 7.1 |
| Node (entorno CI/Dockerfile) | 24.x (requerido) |
| Node (entorno auditoría) | 22.14.0 |
| pnpm | 10.2.0 |

## Arquitectura de aplicación

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│  Vue 3 SPA  │────▶│ Rails 7.1    │────▶│ PostgreSQL  │
│  Dashboard  │     │ API + Web    │     │ (pgvector)  │
│  Widget     │     └──────┬───────┘     └─────────────┘
└─────────────┘            │
                    ┌──────┴───────┐
                    │    Redis     │
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │   Sidekiq    │
                    │   Workers    │
                    └──────────────┘
```

- **Frontend:** Vue 3 + Vite + Tailwind (`app/javascript/`)
- **Backend:** Ruby on Rails 7.1 (`app/`, `config/`, `lib/`)
- **Workers:** Sidekiq (`config/sidekiq.yml`, `Procfile` worker)
- **Base de datos:** PostgreSQL con extensión pgvector
- **Cache/colas:** Redis
- **Almacenamiento:** Active Storage (local por defecto; S3/GCS/Azure configurables)
- **Enterprise:** carpeta `enterprise/` presente (sin modificaciones OptimiA detectadas)

## Imágenes GHCR detectadas

Publicadas por workflow `.github/workflows/build-optimia-chatwoot.yml`:

| Tag | Notas |
|-----|-------|
| `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` | Tag inmutable del último build exitoso |
| `ghcr.io/disruptive-dev/chatwoot:optimia-latest` | Tag flotante (no recomendado en prod) |

También existen versiones históricas en `ghcr.io/pablo-paez-dev/chatwoot` (paquete de usuario).

**Dominio hardcodeado en CI:** `https://app.optimia.spectra-metrics.com`

## Workflows relevantes

| Workflow | Propósito |
|----------|-----------|
| `build-optimia-chatwoot.yml` | Build + push imagen OptimiA a GHCR |
| `publish_foss_docker.yml` | Upstream Chatwoot (no usado por OptimiA) |
| `test_docker_build.yml` | Test build Dockerfile oficial |

## Dockerfiles existentes

| Archivo | Uso actual | Observaciones |
|---------|------------|---------------|
| `Dockerfile` (raíz) | **CI OptimiA** | Single-stage, solo `rails server`, sin Sidekiq, sin HEALTHCHECK, usuario root |
| `docker/Dockerfile` | Referencia upstream | Multi-stage Alpine, optimizado, usado en compose dev |
| `docker/dockerfiles/rails.Dockerfile` | Dev compose | Desarrollo |
| `docker/dockerfiles/vite.Dockerfile` | Dev compose | Vite dev server |

## Personalizaciones OptimiA (resumen)

111 archivos distintos de `upstream/develop`. Categorías principales:

1. **Branding:** logos, `Branding.vue`, `vueapp.html.erb`, locales `en.yml`/`es.yml`, 25 `login.json`
2. **Whitelabel:** `UpdateBanner` deshabilitado en `App.vue`
3. **Spectra Flow:** módulo completo en `lib/integrations/spectra_flow/`, API, UI `@documentos`
4. **Comandos internos:** framework en `helper/internalCommands/` (`@documentos` activo; otros planificados)
5. **CI/CD:** `build-optimia-chatwoot.yml`
6. **Docker:** `Dockerfile` raíz custom

Detalle completo: [`inventory/customizations.md`](../inventory/customizations.md).

## Integración Spectra Flow

- Cliente HTTP: `lib/integrations/spectra_flow/client.rb`
- Endpoints Spectra: `/api/optimia/documents/sendable`, `/download-token`, `/download`
- API Chatwoot: `GET/POST /api/v1/accounts/:id/spectra/documents`
- Configuración por cuenta (`custom_attributes`) o variables de entorno globales
- Health check rake: `spectra_flow:health_check[account_id]`

## Evolution API

**No existe código, configuración ni documentación de Evolution API** en este repositorio (verificado por búsqueda estática).

WhatsApp presente solo como integración nativa de Chatwoot (Cloud API, 360dialog).

## EasyPanel — estado de verificación

| Pregunta | Respuesta |
|----------|-----------|
| ¿Config EasyPanel en repo? | **No** — cero referencias |
| ¿Imagen en prod confirmada? | **No verificable** desde el repositorio |
| ¿Tag en prod confirmado? | **No verificable** |
| ¿Servicios web+worker confirmados? | **No verificable** |

**Acción requerida:** completar [`operations/easypanel-inventory-template.md`](../operations/easypanel-inventory-template.md) manualmente.

## Healthcheck

- Endpoint: `GET /health` → `{"status":"woot"}`
- Implementación: `app/controllers/health_controller.rb`
- Sin autenticación requerida

## Dudas abiertas

1. ¿EasyPanel usa `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6` o construye desde GitHub?
2. ¿Existe servicio Sidekiq separado en EasyPanel?
3. ¿Active Storage es local o S3/R2 en producción?
4. ¿Repositorio canónico será `DSW-Factory/optimia-chatwoot`?
5. ¿Relación entre org `Disruptive-dev` y cuenta `pablo-paez-dev` en GHCR?
