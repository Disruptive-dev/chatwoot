# Diagnóstico — recreación de bandejas OptimiA/Evolution

> Fecha: 2026-07-24  
> Versión: OptimiA 0.1.8 (base `develop` @ `b21f9bb81`)  
> Alcance: staging / código — producción no modificada

## Síntoma

Cuando un usuario **desconecta** un número o **elimina** desde Configuración → Entradas una bandeja API asociada a Evolution, la bandeja **vuelve a aparecer** posteriormente.

## Causa raíz confirmada

La recreación no proviene del monitor periódico (`MonitorConnectionsJob`) de forma directa, sino de **`ConnectionCenterService#provision_chatwoot!` → `ProvisioningService#perform!`**, invocado principalmente por **`refresh_status!`** cuando Evolution reporta sesión `open`.

### Cadena causal

1. El usuario elimina la bandeja o desconecta el número.
2. El registro `OptimiaChannelConnection` **permanece activo** (`state` puede ser `disconnected`, `ready`, etc.; no hay `lifecycle_status` administrativo).
3. `inbox_id` puede seguir apuntando a un inbox borrado, o el inbox sigue existiendo tras desconectar.
4. La UI (`Show.vue`) hace **polling cada 3 s** a `GET .../status` → `refresh_status!` para estados incluyendo `disconnected`.
5. Si Evolution sigue reportando `open` (logout fallido, delay o sesión activa), `apply_remote_status!` llama `provision_chatwoot!`.
6. `ProvisioningService` detecta inbox ausente (`inbox_id` huérfano o `nil`) y **crea un nuevo `Channel::Api` + `Inbox`**.

```ruby
# app/services/optimia/channel_manager/provisioning_service.rb
return @connection.inbox if @connection.inbox_id.present? && @connection.inbox.present?
inbox = find_existing_inbox || create_inbox!  # ← recrea si el inbox fue eliminado
```

```ruby
# app/services/optimia/channel_manager/connection_center_service.rb
when 'connected'
  mark_connected!(connection)
  provision_chatwoot!(connection)  # ← solo evita si state == 'ready'
```

## Evidencia por componente

| Componente | ¿Recrea inbox? | Evidencia |
|------------|----------------|-----------|
| `ProvisioningService` | **Sí** | Único creador de inboxes Chatwoot |
| `ConnectionCenterService#refresh_status!` | **Sí** (indirecto) | Llama `provision_chatwoot!` si Evolution `open` y `state != ready` |
| `MonitorConnectionsJob` | No directamente | Solo `HealthMonitorService` + webhook repair |
| `HealthMonitorService#verify_webhook!` | No | Requiere inbox existente |
| `ChatwootWebhookSyncService` | No | Falla con `inbox_missing` |
| `EvolutionAdapter#ensure_instance!` | No (inbox) | Recupera instancia Evolution, no bandeja Chatwoot |
| Frontend `Show.vue` polling | **Dispara** recreación | Poll 3 s en `disconnected`, `error`, etc. |

## Qué registro permanece activo

- Fila `optimia_channel_connections` con `state` distinto de `disabled`.
- `external_instance_id` sigue presente → monitor y polling siguen operando.
- `inbox_id` puede quedar huérfano (FK impide borrar inbox sin nullificar, pero el provisioning crea otro inbox y actualiza `inbox_id`).

## Callbacks al eliminar inbox Chatwoot

- `InboxesController#destroy` → `DeleteObjectJob` → `inbox.destroy!`
- **No existe** callback OptimiA en `Inbox` ni `has_one :optimia_channel_connection`.
- **No hay** `dependent: :nullify` en la asociación inversa.
- Eliminación desde Entradas **no** marca la conexión como archivada ni deshabilita recreación.

## Relaciones y dependencias

```text
OptimiaChannelConnection --belongs_to--> Inbox (optional, FK restrict)
Inbox --has_many--> conversations, messages (destroy_async)
Inbox --NO--> optimia_channel_connection
```

## Soft delete / archivado

No existe `lifecycle_status`, `archived_at` ni `deleted_at`. Solo `state` operativo sincronizado con Evolution.

## Desconectar vs eliminar (comportamiento actual)

| Acción actual | Evolution | Conexión OptimiA | Inbox | Recreación |
|---------------|-----------|------------------|-------|------------|
| Disconnect API | logout | `state: disconnected` | conservado | Sí, si poll + Evo `open` |
| Eliminar inbox UI | sin cambio | sin cambio / FK block | borrado o bloqueado | Sí, si `inbox_id` huérfano + poll |

## Conclusión

El defecto es la **ausencia de ciclo de vida administrativo** que distinga eliminación intencional de pérdida accidental, combinado con **provisioning automático sin guardas** y **polling agresivo** en estados post-desconexión.

## Corrección planificada

1. Introducir `lifecycle_status` y `inbox_recreation_enabled`.
2. Restringir `ProvisioningService` y monitor a conexiones `lifecycle_status: active`.
3. Servicio central `DeleteConnectionService` + acciones desconectar / desactivar / eliminar.
4. Hook en eliminación de inbox Chatwoot para archivar conexión y deshabilitar recreación.
5. Protección de carreras con `with_lock` y estado `deleting`.
