# Gestión de secretos — OptimiA

## Principios

1. **Nunca** versionar secretos en el repositorio.
2. **Nunca** incluir secretos reales en Docker build args o capas de imagen.
3. **Nunca** documentar valores de secretos en `docs/`.
4. Inyectar secretos en **runtime** vía variables de entorno o vault.
5. Rotar secretos periódicamente y tras incidentes.
6. Separar secretos entre staging y producción.

## Clasificación

| Nivel | Ejemplos | Almacenamiento |
|-------|----------|----------------|
| **Crítico** | `SECRET_KEY_BASE`, `POSTGRES_PASSWORD`, tokens Spectra | Vault / EasyPanel ENV cifrado |
| **Sensible** | `REDIS_PASSWORD`, `SMTP_PASSWORD`, API keys OAuth | EasyPanel ENV |
| **Interno** | `FRONTEND_URL`, `INSTALLATION_NAME` | EasyPanel ENV o build args |
| **Público** | `RAILS_ENV`, `LOG_LEVEL` | ENV sin restricción |

## Secretos por componente

### Rails (web + worker)

| Secreto | Fuente | Rotación |
|---------|--------|----------|
| `SECRET_KEY_BASE` | `rails secret` | Anual o tras compromiso; invalida sesiones |
| `POSTGRES_PASSWORD` | Generado | Anual |
| `REDIS_PASSWORD` | Generado | Anual |
| `ACTIVE_RECORD_ENCRYPTION_*` | `rails db:encryption:init` | Una vez; no rotar sin plan |

### Spectra Flow

| Secreto | Fuente | Alcance |
|---------|--------|---------|
| `spectra_flow_bearer_token` | Admin Spectra / cuenta Chatwoot | Por cuenta |
| `SPECTRA_FLOW_API_TOKEN` | ENV global | Instalación |
| `SPECTRA_FLOW_INBOX_BEARER_TOKEN` | ENV global | Instalación |

Prioridad de resolución (código): cuenta → GlobalConfig DB → ENV.

### Storage (S3/R2)

| Secreto | Notas |
|---------|-------|
| `AWS_ACCESS_KEY_ID` | IAM con mínimo privilegio (solo bucket) |
| `AWS_SECRET_ACCESS_KEY` | Rotar via IAM |
| `STORAGE_ACCESS_KEY_ID` | Para S3-compatible (R2) |

### Email

| Secreto | Notas |
|---------|-------|
| `SMTP_PASSWORD` | Credencial del proveedor SMTP |
| `RAILS_INBOUND_EMAIL_PASSWORD` | Webhook ActionMailbox |

### Monitoreo

| Secreto | Notas |
|---------|-------|
| `SENTRY_DSN` | Por entorno |
| `SENTRY_FRONTEND_DSN` | Separado del backend |

## Build time vs runtime

| Variable | Build (Dockerfile/CI) | Runtime (EasyPanel) |
|----------|----------------------|---------------------|
| `SECRET_KEY_BASE` | Placeholder dummy ✅ | Secret real obligatorio |
| `FRONTEND_URL` | Actualmente hardcodeado ⚠️ | Debería ser runtime |
| `INSTALLATION_NAME` | Build arg OK | También runtime |
| `POSTGRES_PASSWORD` | ❌ Nunca en build | ENV obligatorio |
| Spectra tokens | ❌ Nunca en build | ENV o custom_attributes |

## Filtrado de logs

Chatwoot filtra parámetros sensibles en `config/initializers/filter_parameter_logging.rb`:

```
:password, :secret, :_key, :auth, :crypt, :salt, :certificate,
:otp, :access, :private, :protected, :ssn, :otp_secret, :mfa_token
```

Spectra Flow adicionalmente:
- No loguea valores de bearer token.
- Solo reporta `token_configured: true/false` y `token_source`.

## Prohibiciones

- ❌ Commitear `.env`, `.env.production`, credenciales JSON
- ❌ Secretos en `Dockerfile` ENV permanentes
- ❌ Tokens en URLs de documentación
- ❌ Screenshots de EasyPanel con valores visibles
- ❌ Compartir secretos por chat/email sin cifrado

## Rotación de emergencia

1. Generar nuevo secret.
2. Actualizar en EasyPanel (web + worker).
3. Restart servicios.
4. Verificar funcionalidad.
5. Revocar secret anterior.
6. Documentar incidente.

Para `SECRET_KEY_BASE`: todas las sesiones activas se invalidan.

## Herramientas recomendadas (futuro)

| Herramienta | Propósito |
|-------------|-----------|
| gitleaks | Pre-commit + CI scan |
| `bundle audit` | Vulnerabilidades Ruby |
| `pnpm audit` | Vulnerabilidades JS |
| GitHub secret scanning | Alertas en repo |
| EasyPanel ENV encryption | Almacenamiento seguro |

## Checklist pre-commit

- [ ] No hay archivos `.env` en staging
- [ ] No hay strings que parezcan API keys en código nuevo
- [ ] Logs nuevos no imprimen tokens/passwords
- [ ] Specs usan valores ficticios (`tenant-token`, `example.com`)
