# ADR-004 — Channel Manager Foundation

| Campo | Valor |
|-------|-------|
| **Estado** | ACEPTADO (Sprint 2) |
| **Fecha** | 2026-07-23 |
| **Contexto** | OptimiA necesita onboarding WhatsApp sin exponer Evolution API |

## Decisión

1. Crear modelo propio `OptimiaChannelConnection` como fuente de verdad.
2. Implementar **Provider Registry** con adapter `evolution` como primer provider.
3. Exponer **WhatsApp Connection Center** vía API y UI dedicada bajo `settings/channels/whatsapp`.
4. Delegar mensajería inbound/outbound a la integración nativa Evolution ↔ Chatwoot.
5. Provisionar inbox Chatwoot (`Channel::Api`) de forma idempotente al alcanzar estado `connected`.

## Consecuencias

### Positivas

- Cliente no ve credenciales, instancias ni endpoints técnicos.
- Múltiples números por cuenta.
- Extensible a otros providers (Telegram, Instagram) sin reescribir UI.

### Negativas / trade-offs

- Doble modelo: conexión OptimiA + inbox Chatwoot (sincronizados por provisioning).
- Dependencia de token API server-side para Evolution → Chatwoot.

## Alternativas descartadas

- Usar solo `Channel::Whatsapp` como fuente de verdad → acopla a providers Chatwoot nativos.
- Provider outbound propio en Sprint 2 → fuera de alcance.
