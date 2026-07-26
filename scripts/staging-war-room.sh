#!/usr/bin/env bash
# OptimiA War Room — staging bootstrap checklist (read-only diagnostics + operator steps)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "=== OPTIMIA STAGING WAR ROOM ==="
echo "Branch: $(git branch --show-current)"
echo "HEAD:   $(git log -1 --oneline)"
echo ""

MISSING=()

check_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    MISSING+=("$name")
    echo "  [ ] $name — FALTA"
  else
    echo "  [x] $name — configurada"
  fi
}

echo "Variables requeridas en servicios chatwoot + chatwoot-sidekiq (staging):"
check_env EVOLUTION_API_URL
check_env EVOLUTION_API_KEY
check_env OPTIMIA_CHATWOOT_PUBLIC_URL
check_env OPTIMIA_EVOLUTION_CHATWOOT_API_TOKEN
check_env FRONTEND_URL
check_env SECRET_KEY_BASE
check_env REDIS_URL
check_env POSTGRES_HOST

echo ""
echo "Opcionales:"
check_env OPTIMIA_CHANNEL_MANAGER_ENABLED
check_env OPTIMIA_EVOLUTION_INSTANCE_PREFIX
check_env EVOLUTION_PAIRING_CODE_SUPPORTED

echo ""
echo "Imagen staging objetivo:"
echo "  ghcr.io/pablo-paez-dev/chatwoot:staging-cw-4.10.1-optimia-0.2.0"
echo ""
echo "Registry canónico (objetivo): ghcr.io/dsw-factory/optimia-chatwoot"
echo "Ver: docs/optimia/cicd/README.md"
echo ""
echo "Pasos operador EasyPanel:"
echo "  1. GitHub Actions → OptimiA Build Staging (optimia-build-staging.yml)"
echo "  2. Crear/actualizar proyecto staging con imagen anterior"
echo "  3. bundle exec rails db:migrate (release job o one-off)"
echo "  4. bundle exec rake optimia:channel_manager:health"
echo "  5. Login admin → Configuración → WhatsApp → Conectar número"
echo ""

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "CREDENCIALES FALTANTES (configurar en EasyPanel staging):"
  printf '  - %s\n' "${MISSING[@]}"
  exit 1
fi

echo "Todas las variables requeridas están presentes en este shell."
exit 0
