# Guía manual — Crear staging en EasyPanel

> Paso a paso para el **operador humano**. Solo lectura en prod; **creación** en proyecto nuevo.  
> **No desplegar** hasta completar checklists de aislamiento.

## Prerrequisitos

- [ ] Acceso admin a EasyPanel.
- [ ] Dominio staging disponible (ej. `staging.optimia.spectra-metrics.com`) apuntando al servidor EasyPanel.
- [ ] Imagen staging publicada en GHCR (workflow manual) **o** decisión de usar bootstrap temporal (ver estrategia de imágenes).
- [ ] Secretos staging generados (ver [`staging-variables.md`](../environments/staging-variables.md)).
- [ ] Checklist [`staging-isolation-controls.md`](../environments/staging-isolation-controls.md) impreso o abierto.

## Tiempo estimado

60–90 minutos (primera vez).

---

## Paso 1 — Crear proyecto

1. EasyPanel → **New Project**.
2. Nombre sugerido: `optimia-staging` o `chatwoot-staging`.
3. **No** abrir ni modificar el proyecto de producción.

| Registrar | Valor |
|-----------|-------|
| Nombre proyecto | |
| Fecha creación | |

---

## Paso 2 — PostgreSQL (`chatwoot-staging-db`)

1. En el proyecto staging → **Add Service** → **Database** → PostgreSQL.
2. Configuración sugerida:

| Campo | Valor |
|-------|-------|
| Nombre servicio | `chatwoot-staging-db` |
| Imagen | `pgvector/pgvector:pg16` |
| Database | `chatwoot_staging` |
| User | `chatwoot_staging` |
| Password | *(generar nuevo — anotar en gestor secretos)* |
| Volumen | Habilitado, nombre `chatwoot-staging-pgdata` |

3. **Start** el servicio.
4. Verificar estado **Running**.

> **No** usar credenciales ni hostname de `chatwoot-db`.

---

## Paso 3 — Redis (`chatwoot-staging-redis`)

1. **Add Service** → **App** → Docker Image → `redis:alpine`.
2. Nombre: `chatwoot-staging-redis`.
3. Comando personalizado:

```bash
redis-server --requirepass TU_PASSWORD_NUEVO
```

4. Volumen opcional: `chatwoot-staging-redis-data`.
5. **Start** y verificar Running.

| Registrar | Valor |
|-----------|-------|
| Password Redis | *(en gestor secretos, no en este doc)* |
| Hostname interno | `chatwoot-staging-redis` |

---

## Paso 4 — Preparar variables ENV compartidas

Crear bloque ENV (mismo para web y worker). Usar plantilla de [`staging-variables.md`](../environments/staging-variables.md).

**Verificación obligatoria:**

```text
POSTGRES_HOST=chatwoot-staging-db     ← NO chatwoot-db
REDIS_URL=redis://:...@chatwoot-staging-redis:6379
FRONTEND_URL=https://staging.optimia.spectra-metrics.com
```

---

## Paso 5 — Servicio web (`chatwoot-staging`)

1. **Add Service** → **App** → **Docker Image**.
2. Configuración:

| Campo | Valor |
|-------|-------|
| Nombre | `chatwoot-staging` |
| Image | `ghcr.io/disruptive-dev/chatwoot` |
| Tag | `staging-cw-4.10.1-optimia-0.1.2` |
| Start command | `bundle exec rails server -b 0.0.0.0 -p 3000` |
| Port | `3000` |
| Domain | `staging.optimia.spectra-metrics.com` |
| HTTPS | Habilitar (Let's Encrypt) |
| Restart | Always |

3. **Volumes** → Add:
   - Name: `chatwoot-staging-storage`
   - Mount: `/app/storage`

4. **Environment** → pegar variables del Paso 4.

5. **Health check** (si disponible):
   - Path: `/health`
   - Port: `3000`

6. **No iniciar todavía** si EasyPanel permite defer start — ir al Paso 7 primero.

---

## Paso 6 — Servicio worker (`chatwoot-staging-sidekiq`)

1. **Add Service** → **App** → **Docker Image**.
2. Configuración:

| Campo | Valor |
|-------|-------|
| Nombre | `chatwoot-staging-sidekiq` |
| Image | `ghcr.io/disruptive-dev/chatwoot` |
| Tag | **Mismo que web** |
| Start command | `bundle exec sidekiq -C config/sidekiq.yml` |
| Port | Ninguno |
| Restart | Always |

3. **Volumes**: mismo `chatwoot-staging-storage` → `/app/storage`.
4. **Environment**: **idéntico** al web.
5. **No iniciar** hasta completar migraciones.

---

## Paso 7 — Migraciones (release job)

Ejecutar **una sola vez** sobre BD staging vacía.

### Opción A — Contenedor one-shot en EasyPanel

1. Crear servicio temporal o usar "Run command" si existe.
2. Misma imagen/tag y ENV que web.
3. Comando:

```bash
POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
```

4. Verificar logs: migraciones OK, sin error de conexión.
5. Eliminar o detener servicio temporal.

### Opción B — Consola en contenedor web (tras primer start)

Solo si no hay one-shot; requiere cuidado de no repetir en prod.

```bash
POSTGRES_STATEMENT_TIMEOUT=600s bundle exec rails db:chatwoot_prepare
```

**Confirmar** en logs que `POSTGRES_HOST` es `chatwoot-staging-db`.

---

## Paso 8 — Iniciar servicios

1. **Start** `chatwoot-staging` (web).
2. Esperar healthcheck OK (`/health`).
3. **Start** `chatwoot-staging-sidekiq`.
4. Verificar logs Sidekiq: `Sidekiq starting`.

---

## Paso 9 — Crear super admin (seed mínimo)

En consola del contenedor web (BD staging vacía):

```bash
bundle exec rails runner "User.create!(email: 'admin@staging.local', password: 'CAMBIAR', confirmed_at: Time.now) if User.count.zero?"
```

O usar flujo de signup si `ENABLE_ACCOUNT_SIGNUP=true`.

> Usar email **ficticio**. No emails de clientes reales.

---

## Paso 10 — Smoke tests

| # | Acción | OK |
|---|--------|-----|
| 1 | Abrir `https://staging.optimia.spectra-metrics.com/health` | ☐ |
| 2 | Login dashboard | ☐ |
| 3 | Título muestra "OptimIA Staging" o similar | ☐ |
| 4 | No aparecen conversaciones de prod | ☐ |
| 5 | Crear bandeja de prueba | ☐ |
| 6 | Logs worker sin errores Redis/PG | ☐ |

Si falla el test 4: **detener todo** y revisar aislamiento.

---

## Paso 11 — Registrar despliegue

Completar en [`../operations/easypanel-inventory-template.md`](../operations/easypanel-inventory-template.md) (sección staging) o ticket interno:

| Campo | Valor |
|-------|-------|
| Proyecto EasyPanel | |
| Tag imagen | |
| Commit Git (si conocido) | |
| Fecha deploy | |
| Operador | |

---

## Rollback staging

1. Detener web y worker.
2. Re-deploy tag anterior **staging** (no tag prod).
3. Si BD corrupta: eliminar volumen PG staging y repetir desde Paso 2 (**solo staging**).

---

## Qué NO hacer

- ❌ Editar servicios `chatwoot`, `chatwoot-sidekiq`, `chatwoot-db`, `chatwoot-redis` de producción.
- ❌ Copiar ENV de prod.
- ❌ Restaurar backup prod en staging.
- ❌ Conectar WhatsApp/Facebook/Instagram reales.
- ❌ Cambiar tag `v4.10.1-optimia.6` en producción.

---

## Soporte

- Arquitectura: [`../environments/staging-architecture.md`](../environments/staging-architecture.md)
- Controles: [`../environments/staging-isolation-controls.md`](../environments/staging-isolation-controls.md)
- Imágenes: [`../environments/staging-image-strategy.md`](../environments/staging-image-strategy.md)
