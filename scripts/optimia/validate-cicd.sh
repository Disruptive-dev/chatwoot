#!/usr/bin/env bash
# OptimiA — Validate CI/CD pipeline configuration (static checks)
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORKFLOWS_DIR="${REPO_ROOT}/.github/workflows"
FAILURES=0

fail() {
  echo "FAIL: $1" >&2
  FAILURES=$((FAILURES + 1))
}

pass() {
  echo "PASS: $1"
}

echo "=== OptimiA CI/CD Validation ==="
echo "Root: ${REPO_ROOT}"
echo ""

# 1. Required workflows exist
for wf in optimia-ci.yml optimia-build-staging.yml optimia-build-production.yml; do
  if [ -f "${WORKFLOWS_DIR}/${wf}" ]; then
    pass "Workflow exists: ${wf}"
  else
    fail "Missing workflow: ${wf}"
  fi
done

# 2. Push develop does not trigger production build
if grep -q "push:" "${WORKFLOWS_DIR}/optimia-build-production.yml" 2>/dev/null; then
  if grep -A5 "push:" "${WORKFLOWS_DIR}/optimia-build-production.yml" | grep -q "develop"; then
    fail "optimia-build-production.yml triggers on push to develop"
  fi
fi
pass "Production workflow is not triggered by push to develop"

# 3. Staging tag pattern
if grep -q "staging-cw-" "${WORKFLOWS_DIR}/optimia-build-staging.yml"; then
  pass "Staging workflow accepts staging-cw-* tags"
else
  fail "Staging tag trigger missing"
fi

# 4. No disruptive-dev in active workflows (excluding DEPRECATED files content is ok if no triggers)
ACTIVE_WFS=(
  optimia-ci.yml
  optimia-build-staging.yml
  optimia-build-production.yml
  lint_pr.yml
  size-limit.yml
  auto-assign-pr.yml
)
for wf in "${ACTIVE_WFS[@]}"; do
  if [ -f "${WORKFLOWS_DIR}/${wf}" ] && grep -qi "disruptive-dev" "${WORKFLOWS_DIR}/${wf}"; then
    fail "disruptive-dev found in ${wf}"
  fi
done
pass "No disruptive-dev in active OptimiA workflows"

# 5. Legacy prod workflow deprecated (no push develop)
if grep -q "push:" "${WORKFLOWS_DIR}/build-optimia-chatwoot.yml" 2>/dev/null; then
  if grep -A3 "push:" "${WORKFLOWS_DIR}/build-optimia-chatwoot.yml" | grep -q "develop"; then
    fail "Legacy build-optimia-chatwoot.yml still pushes on develop"
  fi
fi
pass "Legacy production workflow does not auto-build on develop"

# 6. Docker Hub publish guarded
for wf in publish_foss_docker.yml publish_ee_docker.yml; do
  if [ -f "${WORKFLOWS_DIR}/${wf}" ]; then
    if grep -q "chatwoot/chatwoot" "${WORKFLOWS_DIR}/${wf}" && grep -q "chatwoot/chatwoot" "${WORKFLOWS_DIR}/${wf}"; then
      if grep -q "github.repository == 'chatwoot/chatwoot'" "${WORKFLOWS_DIR}/${wf}"; then
        pass "${wf} has upstream guard"
      else
        fail "${wf} missing upstream guard"
      fi
    fi
  fi
done

# 7. Production requires confirmation
if grep -q "DEPLOY_OPTIMIA" "${WORKFLOWS_DIR}/optimia-build-production.yml"; then
  pass "Production requires DEPLOY_OPTIMIA confirmation"
else
  fail "Production missing DEPLOY_OPTIMIA confirmation"
fi

# 8. Production uses environment
if grep -q "environment: production" "${WORKFLOWS_DIR}/optimia-build-production.yml"; then
  pass "Production uses GitHub environment"
else
  fail "Production missing environment: production"
fi

# 9. Digest in staging summary
if grep -q "digest" "${WORKFLOWS_DIR}/optimia-build-staging.yml"; then
  pass "Staging workflow exposes digest"
else
  fail "Staging workflow missing digest output"
fi

# 10. CI does not publish packages
if grep -q "packages: write" "${WORKFLOWS_DIR}/optimia-ci.yml" 2>/dev/null; then
  fail "optimia-ci.yml has packages:write permission"
else
  pass "CI has no packages:write permission"
fi

# 11. Staging and production use same registry default
STG_REG="$(grep -m1 'DEFAULT_REGISTRY:' "${WORKFLOWS_DIR}/optimia-build-staging.yml" | awk '{print $2}')"
PROD_REG="$(grep -m1 'DEFAULT_REGISTRY:' "${WORKFLOWS_DIR}/optimia-build-production.yml" | awk '{print $2}')"
if [ "${STG_REG}" = "${PROD_REG}" ]; then
  pass "Staging and production share default registry: ${STG_REG}"
else
  fail "Registry mismatch: staging=${STG_REG} prod=${PROD_REG}"
fi

# 12. No EasyPanel deploy steps (mentions in docs/summary are OK)
for wf in optimia-build-staging.yml optimia-build-production.yml optimia-ci.yml; do
  if grep -qiE "(deploy.*easypanel|easypanel.*deploy|curl.*easypanel)" "${WORKFLOWS_DIR}/${wf}" 2>/dev/null; then
    fail "${wf} contains EasyPanel deploy action"
  fi
done
pass "No EasyPanel deploy actions in pipeline workflows"

# 13. Upstream CI guarded
for wf in run_foss_spec.yml frontend-fe.yml test_docker_build.yml; do
  if [ -f "${WORKFLOWS_DIR}/${wf}" ]; then
    if grep -q "github.repository == 'chatwoot/chatwoot'" "${WORKFLOWS_DIR}/${wf}"; then
      pass "${wf} guarded for upstream only"
    else
      fail "${wf} missing upstream guard"
    fi
  fi
done

# 14. Concurrency groups
for wf in optimia-build-staging.yml optimia-build-production.yml; do
  if grep -q "concurrency:" "${WORKFLOWS_DIR}/${wf}"; then
    pass "${wf} has concurrency control"
  else
    fail "${wf} missing concurrency"
  fi
done

# 15. Heroku deploy check guarded
if grep -q "github.repository == 'chatwoot/chatwoot'" "${WORKFLOWS_DIR}/deploy_check.yml"; then
  pass "deploy_check.yml guarded"
else
  fail "deploy_check.yml missing guard"
fi

echo ""
if [ "${FAILURES}" -gt 0 ]; then
  echo "=== ${FAILURES} validation(s) FAILED ===" >&2
  exit 1
fi

echo "=== All 15 pipeline validations PASSED ==="
