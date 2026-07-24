#!/usr/bin/env bash
# Non-destructive backup and volume verification helpers for OptimiA staging.
set -euo pipefail

ACTION="${1:-status}"

echo "=== OptimiA backup helper (non-destructive) ==="
echo "action=${ACTION}"
echo "timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

case "${ACTION}" in
  status)
    echo "-- Docker volumes (if docker available) --"
    if command -v docker >/dev/null 2>&1; then
      docker volume ls | grep -E 'evolution|chatwoot|postgres|redis' || true
    else
      echo "docker not available in this shell"
    fi
  ;;
  sizes)
    if command -v docker >/dev/null 2>&1; then
      docker system df -v | grep -E 'evolution|chatwoot|postgres|redis' || true
    fi
  ;;
  verify-mounts)
    echo "Verify on the host/EasyPanel that these paths are mounted:"
    echo "  - evolution_instances -> Evolution WhatsApp sessions"
    echo "  - evolution postgres data volume"
    echo "  - evolution redis data volume"
    echo "  - chatwoot postgres data volume"
    echo "  - chatwoot active storage volume"
  ;;
  backup-plan)
    cat <<'EOF'
Staging backup plan (manual):
1. Snapshot Droplet / volume backups in provider console.
2. pg_dump Chatwoot staging database to encrypted object storage.
3. Export Evolution PostgreSQL if used by Evolution stack.
4. Archive evolution_instances volume (rsync/tar) without deleting source.
5. Record image tags and ENV versions in change log.
EOF
  ;;
  *)
    echo "Usage: $0 [status|sizes|verify-mounts|backup-plan]"
    exit 1
  ;;
esac
