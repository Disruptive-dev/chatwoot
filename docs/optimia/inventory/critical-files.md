# Archivos críticos — OptimiA

> Archivos cuya modificación incorrecta puede romper producción, upgrades o despliegue.

## Nivel crítico

| Archivo | Impacto si se modifica mal | Dependencias |
|---------|---------------------------|--------------|
| `Dockerfile` | Imagen incompleta (sin worker); despliegue roto | CI workflow, EasyPanel |
| `app/javascript/dashboard/components/widgets/conversation/ReplyBox.vue` | Inbox inutilizable; conflictos upstream | Spectra, internalCommands, Editor |
| `config/database.yml` | Conexión BD fallida | PostgreSQL ENV |
| `Procfile` | Migraciones/jobs no ejecutan en Heroku-style deploy | Release, worker |

## Nivel alto

| Archivo | Impacto | Notas |
|---------|---------|-------|
| `config/routes.rb` | API/rota rota | +namespace spectra |
| `config/locales/en.yml` | Mensajes sistema incorrectos | Branding masivo |
| `config/locales/es.yml` | Mensajes sistema incorrectos | Branding masivo |
| `app/javascript/dashboard/App.vue` | UI root rota | UpdateBanner deshabilitado |
| `.github/workflows/build-optimia-chatwoot.yml` | Imagen no se publica o tag incorrecto | GHCR |
| `lib/integrations/spectra_flow/client.rb` | Integración Spectra rota | Tokens, HTTP |
| `docker-compose.production.yaml` | Referencia deploy incorrecta | Usa imagen oficial, no OptimiA |

## Nivel medio

| Archivo | Impacto | Notas |
|---------|---------|-------|
| `app/views/layouts/vueapp.html.erb` | Meta/título/favicon | Branding HTML |
| `app/controllers/api/v1/accounts/spectra/documents_controller.rb` | API documentos | Autorización |
| `config/initializers/cors.rb` | CORS roto | Upstream |
| `config/initializers/rack_attack.rb` | Rate limiting | Seguridad |
| `config/initializers/session_store.rb` | Sesiones | Cookies |
| `config/sidekiq.yml` | Colas worker | Sidekiq |
| `docker/entrypoints/rails.sh` | Startup container | Postgres wait |
| `Gemfile` / `Gemfile.lock` | Dependencias Ruby | Versiones |
| `package.json` / `pnpm-lock.yaml` | Dependencias JS | Versiones |

## Nivel bajo (assets/config)

| Archivo | Impacto |
|---------|---------|
| `public/brand-assets/*` | Logos incorrectos |
| `public/manifest.json` | PWA name incorrecto |
| `app/javascript/shared/components/Branding.vue` | Footer branding |
| `.env.example` | Documentación ENV |

## Archivos que NO deben modificarse en upgrades

| Patrón | Motivo |
|--------|--------|
| `db/migrate/*` existentes | Migraciones inmutables |
| `enterprise/*` sin estrategia EE | Licencia separada |
| `config/initializers/devise.rb` | Auth core |
| `app/models/*` core | Dominio Chatwoot |

## Archivos OptimiA a proteger en merges upstream

```
lib/integrations/spectra_flow/**
app/controllers/api/v1/accounts/spectra/**
app/javascript/dashboard/api/spectra/**
app/javascript/dashboard/helper/internalCommands/**
app/javascript/dashboard/components/widgets/conversation/internalCommands/**
.github/workflows/build-optimia-chatwoot.yml
Dockerfile
public/brand-assets/**
```

## Checklist pre-modificación

Antes de editar un archivo crítico:

- [ ] ¿Es necesario o puede lograrse via configuración?
- [ ] ¿Hay test que cubra el cambio?
- [ ] ¿El diff es mínimo posible?
- [ ] ¿Se documentó en CHANGELOG OptimiA?
- [ ] ¿Se verificó compatibilidad con upstream?
