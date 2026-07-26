#!/usr/bin/env bash
# OptimiA — CI workflow status (read-only, no deploy)
set -euo pipefail

REPO="${GITHUB_REPOSITORY:-pablo-paez-dev/chatwoot}"
TIMEOUT="${OPTIMIA_GH_TIMEOUT:-30}"
WORKFLOW="${1:-optimia-ci.yml}"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI required" >&2
  exit 1
fi

echo "=== OptimiA CI Status ==="
echo "Repository: ${REPO}"
echo "Workflow:   ${WORKFLOW}"
echo ""

RUN_ID="$(timeout "${TIMEOUT}" gh run list \
  --repo "${REPO}" \
  --workflow "${WORKFLOW}" \
  --limit 1 \
  --json databaseId \
  --jq '.[0].databaseId' 2>/dev/null || true)"

if [ -z "${RUN_ID}" ] || [ "${RUN_ID}" = "null" ]; then
  echo "No runs found for ${WORKFLOW}"
  exit 0
fi

timeout "${TIMEOUT}" gh run view "${RUN_ID}" \
  --repo "${REPO}" \
  --json status,conclusion,headBranch,headSha,createdAt,url \
  --jq '"Status: \(.status) | Conclusion: \(.conclusion // "pending")
Branch: \(.headBranch)
SHA:    \(.headSha)
Time:   \(.createdAt)
URL:    \(.url)"'

echo ""
echo "Jobs:"
timeout "${TIMEOUT}" gh run view "${RUN_ID}" --repo "${REPO}" --log-failed 2>/dev/null | tail -20 || \
  timeout "${TIMEOUT}" gh api "repos/${REPO}/actions/runs/${RUN_ID}/jobs" --jq '.jobs[] | "\(.name): \(.status) (\(.conclusion // "running"))"'
