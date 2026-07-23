# Checklist manual de producción — EasyPanel

> Guía paso a paso para recopilar la configuración real de EasyPanel **sin modificar nada**.  
> Completar manualmente y enviar al equipo OptimiA (sin secretos).

---

## ⚠️ ADVERTENCIA DE SEGURIDAD

```
Nunca mostrar valores de SECRET_KEY_BASE, DATABASE_URL, REDIS_URL, tokens,
API keys, contraseñas, SMTP credentials ni claves de storage.
```

- Copiar **solo nombres** de variables de entorno, nunca valores.
- En capturas, ocultar o difuminar campos con valores sensibles.
- No exportar archivos `.env` completos.

---

## Antes de empezar

- [ ] Tengo acceso de **solo lectura** (o administrador con disciplina de no modificar).
- [ ] Tengo un editor de texto para pegar los datos recopilados.
- [ ] Sé qué proyecto de EasyPanel corresponde a OptimiA / Chatwoot.

**Tiempo estimado:** 20–40 minutos.

---

## A. Proyecto EasyPanel

**Dónde mirar:** Panel principal de EasyPanel → lista de proyectos → seleccionar el proyecto de OptimiA.

| Dato a copiar | Tu respuesta |
|---------------|--------------|
| Nombre del proyecto EasyPanel | |
| Dominio productivo configurado | |
| Cantidad total de servicios en el proyecto | |
| Fecha visible del último deploy (si aparece) | |

**Captura recomendada:** Pantalla general del proyecto mostrando todos los servicios.

---

## B. Servicio web

**Dónde mirar:** Proyecto → servicio principal (suele llamarse `web`, `app`, `chatwoot`, `rails` o `optimia-web`) → pestaña **Source** / **General** / **Deploy**.

### B.1 Origen del deploy

Marcar el tipo que corresponda:

- [ ] GitHub (repositorio + rama)
- [ ] Docker image (imagen + tag)
- [ ] Dockerfile en repo
- [ ] Docker Compose
- [ ] Otro: _______________

| Dato a copiar | Tu respuesta |
|---------------|--------------|
| Nombre exacto del servicio | |
| Repositorio GitHub (si aparece) | |
| Rama (si aparece) | |
| Imagen Docker exacta (si aparece) | |
| **Tag exacto** | |
| Digest SHA256 (si aparece) | |
| Comando de inicio / Start command | |
| Puerto expuesto | |
| Healthcheck configurado (sí/no + ruta) | |
| Política de restart | |
| Volúmenes montados (nombre + ruta contenedor) | |

**Capturas recomendadas:**
1. Pestaña Source / imagen del servicio web.
2. Comando de inicio y puerto.
3. Configuración de healthcheck (si existe).

**Referencia CI (no asumir desplegada):** `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6`

---

## C. Worker (Sidekiq)

**Dónde mirar:** Lista de servicios del mismo proyecto. Buscar nombres como:

```
worker
sidekiq
chatwoot-worker
optimia-worker
```

| Dato a copiar | Tu respuesta |
|---------------|--------------|
| **¿Existe servicio worker separado?** | ☐ Sí  ☐ No |
| Nombre del servicio (si existe) | |
| Imagen Docker | |
| Tag exacto | |
| Comando de inicio | |
| Política de restart | |
| ¿Comparte imagen con el servicio web? | ☐ Sí  ☐ No  ☐ Desconocido |
| ¿Tiene acceso a PostgreSQL? (mismas vars) | ☐ Sí  ☐ No  ☐ Desconocido |
| ¿Tiene acceso a Redis? (mismas vars) | ☐ Sí  ☐ No  ☐ Desconocido |

**Comando esperado (referencia, no modificar):**

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

> Si **no existe** worker: anotar "NO EXISTE" — es un hallazgo crítico. **No crear ni modificar** el servicio todavía.

**Captura recomendada:** Lista de servicios mostrando si hay worker. Si existe, captura de su configuración (sin secretos).

---

## D. PostgreSQL

**Dónde mirar:** Servicio de base de datos en el mismo proyecto o servicio externo vinculado.

| Dato a copiar | Tu respuesta |
|---------------|--------------|
| Nombre del servicio | |
| Versión de PostgreSQL (si visible) | |
| Estado (running / stopped) | |
| Nombre del volumen persistente | |
| ¿Existe política de backup visible? | ☐ Sí  ☐ No |
| Frecuencia de backup (si aparece) | |
| Fecha del último backup visible | |
| ¿Backup automático habilitado? | ☐ Sí  ☐ No  ☐ Desconocido |

**No copiar:** usuario, contraseña, connection string, `DATABASE_URL` con valor.

**Captura recomendada:** Configuración del servicio PostgreSQL **sin** credenciales visibles.

---

## E. Redis

**Dónde mirar:** Servicio Redis en el proyecto.

| Dato a copiar | Tu respuesta |
|---------------|--------------|
| Nombre del servicio | |
| Versión (si visible) | |
| Estado | |
| Nombre del volumen (si tiene) | |
| Autenticación habilitada | ☐ Sí  ☐ No  ☐ Desconocido |

**No copiar:** contraseña, `REDIS_URL` con valor.

**Captura recomendada:** Configuración Redis sin credenciales.

---

## F. Active Storage

**Dónde mirar:** Variables de entorno del servicio web/worker + volúmenes montados.

Determinar el modo **solo por nombres de variables y volúmenes** (no por valores):

| Modo | Indicadores |
|------|-------------|
| Local | Volumen `/app/storage`, `ACTIVE_STORAGE_SERVICE=local` |
| S3 | `S3_BUCKET_NAME`, `AWS_ACCESS_KEY_ID` |
| R2 | `STORAGE_ENDPOINT`, `STORAGE_BUCKET_NAME`, `s3_compatible` |
| GCS | `GCS_BUCKET`, `GCS_CREDENTIALS` |
| Azure | `AZURE_STORAGE_*` |

| Dato a copiar | Tu respuesta |
|---------------|--------------|
| Modo detectado | ☐ Local  ☐ S3  ☐ R2  ☐ GCS  ☐ Azure  ☐ Desconocido |
| Nombres de variables relacionadas (sin valores) | |
| Nombre del volumen o bucket (sin credenciales) | |

**No copiar:** access keys, secret keys, tokens.

---

## G. Variables de entorno (solo nombres)

**Dónde mirar:** Servicio web → Environment / Variables. Repetir para worker si existe.

Copiar **únicamente los nombres**. Agrupar:

### Rails

```
SECRET_KEY_BASE
FRONTEND_URL
RAILS_ENV
FORCE_SSL
RAILS_LOG_TO_STDOUT
LOG_LEVEL
...
```

### PostgreSQL

```
POSTGRES_HOST
POSTGRES_USERNAME
POSTGRES_PASSWORD        ← solo nombre, NO valor
POSTGRES_DATABASE
DATABASE_URL             ← solo nombre, NO valor
...
```

### Redis

```
REDIS_URL                ← solo nombre, NO valor
REDIS_PASSWORD           ← solo nombre, NO valor
...
```

### URL / dominio

```
FRONTEND_URL
HELPCENTER_URL
ASSET_CDN_HOST
...
```

### Correo

```
MAILER_SENDER_EMAIL
SMTP_ADDRESS
SMTP_PORT
SMTP_USERNAME
SMTP_PASSWORD            ← solo nombre, NO valor
...
```

### Storage

```
ACTIVE_STORAGE_SERVICE
S3_BUCKET_NAME
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
STORAGE_ENDPOINT
STORAGE_BUCKET_NAME
...
```

### Seguridad

```
ENABLE_RACK_ATTACK
ENABLE_ACCOUNT_SIGNUP
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY
...
```

### Spectra Flow

```
SPECTRA_FLOW_API_URL
SPECTRA_FLOW_API_TOKEN
SPECTRA_FLOW_INBOX_BEARER_TOKEN
...
```

### Chatwoot / branding

```
INSTALLATION_NAME
BRAND_NAME
CW_API_ONLY_SERVER
...
```

### Sidekiq

```
SIDEKIQ_CONCURRENCY
...
```

### Sentry

```
SENTRY_DSN
SENTRY_FRONTEND_DSN
...
```

**Captura recomendada:** Listado de variables con **valores ocultos** (EasyPanel suele tener botón de visibilidad — mantener ocultos al capturar).

---

## H. Cadena de trazabilidad

Completar esta tabla para verificar si producción coincide con el repositorio y CI:

| Eslabón | Valor conocido (repo/CI) | Valor en EasyPanel | ¿Coincide? |
|---------|--------------------------|-------------------|------------|
| **Commit Git** | `462802c9e` (funcional) / `5ab2bb5e4` (docs) | | ☐ Sí ☐ No ☐ N/A |
| **Workflow** | `build-optimia-chatwoot.yml` | | ☐ Sí ☐ No ☐ N/A |
| **Imagen GHCR** | `ghcr.io/disruptive-dev/chatwoot` | | ☐ Sí ☐ No |
| **Tag** | `v4.10.1-optimia.6` (detectado en CI) | | ☐ Sí ☐ No |
| **Digest SHA256** | *(desconocido)* | | |
| **Servicio EasyPanel** | *(pendiente)* | | |
| **Fecha deploy** | *(desconocido)* | | |

### Pregunta clave

¿Producción corre exactamente esta imagen?

```
ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6
```

- [ ] Sí — tag coincide
- [ ] No — tag diferente: _______________
- [ ] No sé — no aparece tag claro
- [ ] Construye desde GitHub, no desde GHCR

### Rupturas detectadas

| # | Descripción |
|---|-------------|
| 1 | |
| 2 | |

---

## I. Capturas recomendadas (sin secretos)

Enviar estas capturas con valores sensibles ocultos:

| # | Captura | Incluir |
|---|---------|---------|
| 1 | Vista general del proyecto | Todos los servicios visibles |
| 2 | Source del servicio web | Repo/imagen/tag |
| 3 | Comando y puerto del web | Start command, port |
| 4 | Lista completa de servicios | Para verificar worker |
| 5 | Configuración del worker | Si existe |
| 6 | PostgreSQL | Sin credenciales |
| 7 | Redis | Sin credenciales |
| 8 | Volúmenes | Nombres y rutas |
| 9 | Variables de entorno | Nombres visibles, **valores ocultos** |

---

## J. Envío al equipo

Al completar, enviar:

1. Este documento rellenado (tablas completadas).
2. Las 9 capturas indicadas.
3. Confirmación explícita: **"No modifiqué nada en EasyPanel"**.

**Destino:** equipo OptimiA / responsable técnico.

**Siguiente paso tras envío:** el equipo analizará la trazabilidad y autorizará (o no) el Sprint 1 técnico.

---

## Referencias

- Plantilla detallada: [`easypanel-inventory-template.md`](easypanel-inventory-template.md)
- Estado del proyecto: [`../../project/PROJECT-STATUS.md`](../../project/PROJECT-STATUS.md)
- Imagen CI (referencia): `ghcr.io/disruptive-dev/chatwoot:v4.10.1-optimia.6`
