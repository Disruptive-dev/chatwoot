#!/usr/bin/env bash
# OptimiA — Generate release metadata JSON from workflow artifact or inputs
set -euo pipefail

OPTIMIA_VERSION="${1:-}"
CHATWOOT_VERSION="${2:-4.10.1}"
COMMIT_SHA="${3:-$(git rev-parse HEAD 2>/dev/null || echo unknown)}"
REGISTRY="${OPTIMIA_GHCR_REGISTRY:-ghcr.io/pablo-paez-dev/chatwoot}"
ENVIRONMENT="${4:-staging}"

usage() {
  echo "Usage: $0 <optimia_version> [chatwoot_version] [commit_sha] [staging|production]" >&2
  exit 1
}

[ -n "${OPTIMIA_VERSION}" ] || usage

if [ "${ENVIRONMENT}" = "production" ]; then
  TAG="cw-${CHATWOOT_VERSION}-optimia-${OPTIMIA_VERSION}"
else
  TAG="staging-cw-${CHATWOOT_VERSION}-optimia-${OPTIMIA_VERSION}"
fi

IMAGE="${REGISTRY}:${TAG}"
BUILT_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

cat <<EOF
{
  "image": "${IMAGE}",
  "tag": "${TAG}",
  "commit_sha": "${COMMIT_SHA}",
  "optimia_version": "${OPTIMIA_VERSION}",
  "chatwoot_version": "${CHATWOOT_VERSION}",
  "registry": "${REGISTRY}",
  "environment": "${ENVIRONMENT}",
  "built_at_utc": "${BUILT_AT}",
  "note": "Run optimia/image-inspect.sh after publish to obtain digest"
}
EOF
