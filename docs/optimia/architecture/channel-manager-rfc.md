# RFC — OptimiA Channel Manager Foundation

> Sprint 2 — MEGA SPRINT 2  
> Estado: IMPLEMENTADO (foundation + Connection Center)

## Objetivo

Introducir un **Channel Manager propio** en OptimiA que abstraiga Evolution API y exponga al cliente final únicamente:

```text
Configuración → Canales → WhatsApp → Conectar número
```

## Componentes

| Capa | Ubicación | Responsabilidad |
|------|-----------|-----------------|
| Modelo | `OptimiaChannelConnection` | Fuente de verdad de conexiones |
| Auditoría | `OptimiaChannelConnectionAudit` | Trazabilidad de acciones |
| Registry | `Integrations::Optimia::ChannelManager::ProviderRegistry` | Registro de providers |
| Adapter | `Providers::EvolutionAdapter` | Integración Evolution server-side |
| Orquestación | `Optimia::ChannelManager::ConnectionCenterService` | Flujo QR, estado, reconexión |
| Provisioning | `Optimia::ChannelManager::ProvisioningService` | Inbox Chatwoot idempotente |
| API | `Api::V1::Accounts::Optimia::Whatsapp::ConnectionsController` | API account-scoped |
| UI | `settings/channels/whatsapp/*` | Listado, wizard, QR, polling |

## Fuera de alcance (Sprint 2)

- Pipeline inbound/outbound propio
- Provider de mensajería Chatwoot
- Migración de clientes existentes
- Borrado físico de instancias Evolution

Evolution continúa usando su integración nativa con Chatwoot para mensajería.

## Variables de entorno

| Variable | Uso |
|----------|-----|
| `EVOLUTION_API_URL` | URL base Evolution (server-side) |
| `EVOLUTION_API_KEY` | API key global Evolution |
| `OPTIMIA_CHATWOOT_PUBLIC_URL` | URL pública Chatwoot para Evolution |
| `OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN` | Token API Chatwoot para Evolution |
| `OPTIMIA_CHANNEL_MANAGER_ENABLED` | Kill switch global |
| `EVOLUTION_PAIRING_CODE_SUPPORTED` | Habilita pairing code en UI |

## Feature flag

- `optimia_channel_manager` en `config/features.yml`

## API

```text
GET    /api/v1/accounts/:account_id/optimia/whatsapp/connections
POST   /api/v1/accounts/:account_id/optimia/whatsapp/connections
GET    /api/v1/accounts/:account_id/optimia/whatsapp/connections/:id
GET    /api/v1/accounts/:account_id/optimia/whatsapp/connections/:id/status
POST   /api/v1/accounts/:account_id/optimia/whatsapp/connections/:id/qr
POST   /api/v1/accounts/:account_id/optimia/whatsapp/connections/:id/reconnect
POST   /api/v1/accounts/:account_id/optimia/whatsapp/connections/:id/disconnect
POST   /api/v1/accounts/:account_id/optimia/whatsapp/connections/:id/pairing_code
```

## Máquina de estados

```text
draft → creating → created → waiting_qr → waiting_scan → pairing → connected → syncing → ready
                                                                              ↓
                                                                         disconnected / error / disabled
```

## Seguridad

Ver `docs/optimia/security/channel-manager-security.md`.
