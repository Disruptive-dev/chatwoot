# Ciclo de vida administrativo — conexiones OptimiA/Evolution

> Versión: OptimiA 0.1.8+  
> Diagnóstico: [`connection-lifecycle-diagnosis.md`](connection-lifecycle-diagnosis.md)

## Tres capas de estado

| Capa | Campo / origen | Propósito |
|------|----------------|-----------|
| **Administrativo OptimiA** | `lifecycle_status` | Intención del operador: activo, archivado, eliminando, eliminado |
| **Operativo / remoto** | `state` | Máquina de estados sincronizada con Evolution (QR, ready, disconnected…) |
| **Bandeja Chatwoot** | `inbox_id` + fila `inboxes` | Entrada API usada por agentes y conversaciones |

El monitor y el provisioning **solo** actúan cuando `lifecycle_status == active` y `inbox_recreation_enabled == true`.

## Estados administrativos (`lifecycle_status`)

| Estado | Monitor | Recrear inbox | Descripción |
|--------|---------|---------------|-------------|
| `active` | Sí | Sí (configurable) | Operación normal |
| `inactive` | No | No | Pausado por operador |
| `disconnected` | No | No | Reservado; desconectar usa `state: disconnected` con lifecycle `active` |
| `archived` | No | No | Desactivado o bandeja eliminada desde Entradas |
| `deleting` | No | No | Eliminación en curso (bloqueo de carreras) |
| `deleted` | No | No | Eliminación completada (registro conservado para auditoría) |
| `error` | No | No | Eliminación incompleta; requiere intervención |

## Acciones del operador

### A. Desconectar WhatsApp (`POST .../disconnect`)

- Cierra sesión Evolution (logout).
- Conserva conexión OptimiA e inbox.
- `lifecycle_status` permanece `active`.
- `state` → `disconnected`.
- Permite reconectar con QR.
- No elimina conversaciones.

### B. Desactivar conexión (`POST .../deactivate`)

- `lifecycle_status` → `archived`.
- `inbox_recreation_enabled` → `false`.
- Detiene monitor y reconciliación.
- Conserva inbox e instancia Evolution.
- Restaurable (`POST .../restore`).

### C. Eliminar definitivamente (`DELETE .../connections/:id`)

Flujo idempotente vía `DeleteConnectionService`:

1. `deleting` + deshabilitar recreación  
2. Logout Evolution (best effort)  
3. Borrar instancia Evolution (best effort, 404 tolerado)  
4. Limpiar webhook del canal API  
5. Opcionalmente destruir inbox Chatwoot (`delete_inbox=true`)  
6. `deleted` + auditoría  

Repetir la operación no lanza excepciones ni recrea bandejas.

### Eliminación desde Configuración → Entradas

Al destruir un inbox administrado por OptimiA:

1. `InboxDeletionCoordinator` archiva la conexión.  
2. `inbox_id` se anula antes del `destroy`.  
3. `inbox_recreation_enabled` → `false`.  
4. El monitor no recrea la bandeja.

## Política del monitor

`MonitorConnectionsJob` procesa solo conexiones `monitorable` (lifecycle `active`).

Si una conexión **activa** pierde su inbox accidentalmente:

- Se registra alerta `inbox_inconsistent`.
- Si `OPTIMIA_AUTO_REPAIR_MISSING_INBOX=true` (default), se repara vía `ProvisioningService`.
- Si `false`, solo alerta; no recrea.

Conexiones `archived`, `deleting` o `deleted` **nunca** recrean inbox.

## Política de conversaciones

Eliminar el inbox Chatwoot (acción definitiva o desde Entradas con destroy) sigue el comportamiento estándar de Chatwoot 4.10.1:

- `Inbox` tiene `has_many :conversations, dependent: :destroy_async`.
- Destruir inbox programa borrado de conversaciones y mensajes asociados.

Por eso **desactivar/archivar** es la acción segura por defecto; **eliminar definitivamente** es avanzada y muestra confirmación explícita.

## Protección de carreras

- `with_lock` en servicios de lifecycle y coordinador de inbox.
- Estado `deleting` impide provisioning y monitor.
- Si `MonitorConnectionsJob` corre durante una eliminación, no recrea inbox porque `inbox_recreation_enabled` ya es `false`.

## Recuperación y rollback

| Situación | Acción |
|-----------|--------|
| Desactivación accidental | `POST .../restore` |
| Eliminación incompleta (`lifecycle_status: error`) | Revisar `deletion_error`, reintentar `DELETE` o limpieza manual Evolution |
| Inbox huérfano antes del fix | Archivar conexión manualmente y `inbox_recreation_enabled: false` |

## Variables relevantes

| Variable | Default | Efecto |
|----------|---------|--------|
| `OPTIMIA_AUTO_REPAIR_MISSING_INBOX` | `true` | Reparación automática de inbox perdido en conexión activa |

## Auditoría

Eventos en `optimia_channel_connection_audits`: `archived`, `archived_from_inbox_deletion`, `restored`, `deletion_started`, `deleted`, `deletion_failed`, `inbox_removed`.

Logs estructurados: `optimia_connection_lifecycle_action`, `optimia_connection_inbox_deletion_coordinated` (sin secretos, teléfonos completos ni QR).
