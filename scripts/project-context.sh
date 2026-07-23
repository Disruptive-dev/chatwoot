#!/usr/bin/env bash
# OptimiA — project context (read-only diagnostic)
# Usage: bash scripts/project-context.sh
# Does NOT: pull, push, change branches, modify files, or print secrets.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

divider() { echo "────────────────────────────────────────"; }

echo "=== OPTIMIA PROJECT CONTEXT ==="
echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
divider

echo "Ruta:           $REPO_ROOT"
echo "Rama:           $(git branch --show-current 2>/dev/null || echo 'unknown')"

LAST_COMMIT="$(git log -1 --oneline 2>/dev/null || echo 'no commits')"
echo "Último commit:  $LAST_COMMIT"

echo ""
echo "Estado Git:"
git status --short --branch 2>/dev/null || echo "  (git status unavailable)"

echo ""
echo "Remotes:"
git remote -v 2>/dev/null | sed 's/^/  /' || echo "  (no remotes)"

BRANCH="$(git branch --show-current 2>/dev/null || echo 'develop')"
if git rev-parse --verify "origin/$BRANCH" >/dev/null 2>&1; then
  COUNTS="$(git rev-list --left-right --count "HEAD...origin/$BRANCH" 2>/dev/null || echo "? ?")"
  AHEAD="${COUNTS%% *}"
  BEHIND="${COUNTS##* }"
  echo ""
  echo "vs origin/$BRANCH:  +$AHEAD ahead  -$BEHIND behind"
else
  echo ""
  echo "vs origin/$BRANCH:  (remote branch not found locally)"
fi

if git rev-parse --verify upstream/develop >/dev/null 2>&1; then
  UP_COUNTS="$(git rev-list --left-right --count HEAD...upstream/develop 2>/dev/null || echo "? ?")"
  UP_AHEAD="${UP_COUNTS%% *}"
  UP_BEHIND="${UP_COUNTS##* }"
  echo "vs upstream/develop: +$UP_AHEAD ahead  -$UP_BEHIND behind"
fi

echo ""
echo "Archivos modificados (working tree):"
MODIFIED="$(git status --porcelain 2>/dev/null | grep -v '^??' || true)"
if [ -z "$MODIFIED" ]; then
  echo "  (ninguno)"
else
  echo "$MODIFIED" | sed 's/^/  /'
fi

echo ""
echo "Archivos sin seguimiento:"
UNTRACKED="$(git status --porcelain 2>/dev/null | grep '^??' || true)"
if [ -z "$UNTRACKED" ]; then
  echo "  (ninguno)"
else
  echo "$UNTRACKED" | sed 's/^/  /'
fi

divider
echo "Tags OptimiA / baseline:"
BASELINE_TAGS="$(git tag -l 'chatwoot-base/*' 2>/dev/null || true)"
OPTIMIA_TAGS="$(git tag -l 'optimia/*' 2>/dev/null || true)"
if [ -n "$BASELINE_TAGS" ]; then
  echo "$BASELINE_TAGS" | sed 's/^/  /'
else
  echo "  (ningún tag chatwoot-base/*)"
fi
if [ -n "$OPTIMIA_TAGS" ]; then
  echo "$OPTIMIA_TAGS" | sed 's/^/  /'
else
  echo "  (ningún tag optimia/*)"
fi

divider
HANDOFF="docs/project/SPRINT-HANDOFF.md"
if [ -f "$HANDOFF" ]; then
  echo "Último handoff (extracto):"
  awk '/^## Sprint/{if(s++)exit} s' "$HANDOFF" | head -20 | sed 's/^/  /'
else
  echo "Último handoff:  (archivo no encontrado: $HANDOFF)"
fi

divider
STATUS="docs/project/PROJECT-STATUS.md"
if [ -f "$STATUS" ]; then
  echo "Próximo paso documentado:"
  awk '/^## Próximo paso exacto$/,/^## |^$/{if(/^## Próximo/)next; if(/^## /)exit; print}' "$STATUS" | sed 's/^/  /' | head -5
else
  echo "Próximo paso:  (ver docs/project/PROJECT-STATUS.md)"
fi

divider
echo "Documentación clave:"
for f in docs/project/PROJECT-STATUS.md docs/project/SPRINT-HANDOFF.md docs/optimia/README.md; do
  if [ -f "$f" ]; then
    echo "  ✓ $f"
  else
    echo "  ✗ $f (missing)"
  fi
done

echo ""
echo "=== END CONTEXT ==="
