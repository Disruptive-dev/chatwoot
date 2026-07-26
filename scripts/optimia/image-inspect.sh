#!/usr/bin/env bash
# OptimiA — Inspect container image digest (read-only)
set -euo pipefail

IMAGE="${1:-}"
TIMEOUT="${OPTIMIA_GH_TIMEOUT:-30}"

usage() {
  echo "Usage: $0 <image[:tag]|digest>" >&2
  echo "Example: $0 ghcr.io/pablo-paez-dev/chatwoot:staging-cw-4.10.1-optimia-0.2.0" >&2
  exit 1
}

[ -n "${IMAGE}" ] || usage

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker required" >&2
  exit 1
fi

echo "=== OptimiA Image Inspect ==="
echo "Image: ${IMAGE}"
echo ""

if ! timeout "${TIMEOUT}" docker manifest inspect "${IMAGE}" > /tmp/optimia-manifest.json 2>/dev/null; then
  echo "ERROR: Cannot inspect ${IMAGE} (not found or auth required)" >&2
  exit 1
fi

if command -v jq >/dev/null 2>&1; then
  DIGEST="$(jq -r '.config.digest // .manifests[0].digest // .Descriptor.digest // empty' /tmp/optimia-manifest.json)"
  if [ -n "${DIGEST}" ]; then
    echo "Digest: ${DIGEST}"
  fi
  jq -r '.mediaType, .schemaVersion' /tmp/optimia-manifest.json 2>/dev/null || true
else
  timeout "${TIMEOUT}" docker manifest inspect "${IMAGE}" | head -30
fi

echo ""
echo "Use this digest in EasyPanel (never use :latest for production)."
