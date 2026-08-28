#!/usr/bin/env bash
# tstack: upstream-audit.sh — Fetch upstream/main, merge with local changes, run full security audit
# Intended to run as a recurring Hermes cron job. Reports results but NEVER pushes.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

REMOTE_ORIGIN="origin"
REMOTE_UPSTREAM="upstream"
AUDIT_BRANCH="security/upstream-audit-$(date +%Y%m%d-%H%M%S)"

echo "=== tstack Upstream Audit $(date -u +%Y-%m-%dT%H:%M:%SZ) ==="
echo "Repo: $REPO_ROOT"

echo "--- Fetching $REMOTE_UPSTREAM/main ---"
git fetch "$REMOTE_UPSTREAM" main --quiet

LOCAL_MAIN=$(git rev-parse "$REMOTE_ORIGIN/main")
UPSTREAM_MAIN=$(git rev-parse "$REMOTE_UPSTREAM/main")

echo "Local $REMOTE_ORIGIN/main: $LOCAL_MAIN"
echo "Upstream $REMOTE_UPSTREAM/main: $UPSTREAM_MAIN"

if [ "$LOCAL_MAIN" = "$UPSTREAM_MAIN" ]; then
    echo "STATUS: Fork main is already in sync with upstream/main. Nothing to audit."
    exit 0
fi

NEW_COMMITS=$(git rev-list --count "$LOCAL_MAIN..$UPSTREAM_MAIN")
echo "STATUS: Fork is $NEW_COMMITS commit(s) behind upstream. Auditing..."

echo "--- Running baseline tests on current main ---"
BASELINE_PASS=0
BASELINE_FAIL=0
if bun test browse/test/browser-skill-commands.test.ts browse/test/url-validation.test.ts test/action-pinning.test.ts test/audit-compliance.test.ts >/tmp/baseline-test.log 2>&1; then
    BASELINE_PASS=$(grep -oP '\d+(?= pass)' /tmp/baseline-test.log | head -1)
    BASELINE_FAIL=0
else
    BASELINE_PASS=$(grep -oP '\d+(?= pass)' /tmp/baseline-test.log | head -1 || echo 0)
    BASELINE_FAIL=$(grep -oP '\d+(?= fail)' /tmp/baseline-test.log | head -1 || echo 0)
fi
echo "Baseline: ${BASELINE_PASS:-0} pass, ${BASELINE_FAIL:-0} fail"

echo "--- Creating audit branch: $AUDIT_BRANCH ---"
git checkout -b "$AUDIT_BRANCH" "$REMOTE_ORIGIN/main" --quiet

echo "--- Merging upstream/main into audit branch ---"
MERGE_CONFLICTS=""
if git merge "$UPSTREAM_MAIN" --no-edit --quiet 2>/tmp/merge.log; then
    echo "Merge: clean (no conflicts)"
else
    CONFLICTS=$(git diff --name-only --diff-filter=U 2>/dev/null || true)
    MERGE_CONFLICTS="$CONFLICTS"
    echo "Merge: CONFLICTS in:"
    echo "$CONFLICTS" | sed 's/^/  - /'
    git merge --abort 2>/dev/null || true
    echo ""
    echo "=== AUDIT RESULT ==="
    echo "STATUS: BLOCKED — merge conflicts prevent automated audit."
    echo "Conflicting files:"
    echo "$CONFLICTS"
    git checkout - 2>/dev/null || true
    git branch -D "$AUDIT_BRANCH" 2>/dev/null || true
    exit 1
fi

echo "--- Running tests on merged code ---"
MERGED_PASS=0
MERGED_FAIL=0
MERGED_TEST_LOG="/tmp/merged-test-$AUDIT_BRANCH.log"
if bun test browse/test/browser-skill-commands.test.ts browse/test/url-validation.test.ts test/action-pinning.test.ts test/audit-compliance.test.ts >"$MERGED_TEST_LOG" 2>&1; then
    MERGED_PASS=$(grep -oP '\d+(?= pass)' "$MERGED_TEST_LOG" | head -1)
    MERGED_FAIL=0
else
    MERGED_PASS=$(grep -oP '\d+(?= pass)' "$MERGED_TEST_LOG" | head -1 || echo 0)
    MERGED_FAIL=$(grep -oP '\d+(?= fail)' "$MERGED_TEST_LOG" | head -1 || echo 0)
fi
echo "Merged: ${MERGED_PASS:-0} pass, ${MERGED_FAIL:-0} fail"

echo "--- Running build on merged code ---"
BUILD_OK=false
if bun run build >/tmp/build-$AUDIT_BRANCH.log 2>&1; then
    BUILD_OK=true
    echo "Build: OK"
else
    echo "Build: FAILED"
fi

echo "--- Checking GitHub Actions still SHA-pinned ---"
ACTIONS_UNPINNED=$(grep -E '^\s+- uses: [^@/]+\/[^@/]+@v\d' .github/workflows/*.yml 2>/dev/null || true)
if [ -n "$ACTIONS_UNPINNED" ]; then
    echo "WARNING: Mutable action tags introduced:"
    echo "$ACTIONS_UNPINNED" | sed 's/^/  /'
else
    echo "Actions: all still SHA-pinned"
fi

echo "--- Checking trust policy survived ---"
TRUST_VIOLATION=""
SPAWN_BUN=$(grep -E 'Bun\.spawn\(\['"'"'bun'"'"']' browse/src/browser-skill-commands.ts 2>/dev/null || true)
if [ -n "$SPAWN_BUN" ]; then
    echo "WARNING: spawnSkill uses bare 'bun' instead of process.execPath"
    TRUST_VIOLATION="yes"
fi
OPERATOR_GRANT=$(grep -c 'operatorTrustGranted' browse/src/browser-skill-commands.ts 2>/dev/null || echo 0)
if [ "$OPERATOR_GRANT" -lt 3 ]; then
    echo "WARNING: operatorTrustGranted references missing — trust policy may have been reverted"
    TRUST_VIOLATION="yes"
fi
if [ -z "$TRUST_VIOLATION" ]; then
    echo "Trust policy: intact"
fi

echo ""
echo "========================================="
echo "AUDIT REPORT — $AUDIT_BRANCH"
echo "========================================="
echo "Upstream: $UPSTREAM_MAIN"
echo "Local:    $LOCAL_MAIN"
echo "Behind by: $NEW_COMMITS commits"
echo ""
echo "Tests (baseline → merged): ${BASELINE_PASS:-0}p/${BASELINE_FAIL:-0}f → ${MERGED_PASS:-0}p/${MERGED_FAIL:-0}f"
echo "Build: $([ "$BUILD_OK" = true ] && echo OK || echo FAILED)"
echo "Actions unpinned: $([ -z "$ACTIONS_UNPINNED" ] && echo 'none' || echo 'YES')"
echo "Trust policy violations: $([ -z "$TRUST_VIOLATION" ] && echo 'none' || echo 'YES')"
echo ""

AUDIT_PASS=true
if [ "${MERGED_FAIL:-0}" -gt "${BASELINE_FAIL:-0}" ]; then
    AUDIT_PASS=false
    echo "VERDICT: FAIL — test regressions introduced"
fi
if [ "$BUILD_OK" = false ]; then
    AUDIT_PASS=false
    echo "VERDICT: FAIL — build broken"
fi
if [ -n "$ACTIONS_UNPINNED" ]; then
    AUDIT_PASS=false
    echo "VERDICT: FAIL — mutable actions introduced"
fi
if [ -n "$TRUST_VIOLATION" ]; then
    AUDIT_PASS=false
    echo "VERDICT: FAIL — trust policy weakened"
fi

if [ "$AUDIT_PASS" = true ]; then
    echo "VERDICT: PASS — upstream changes are safe to merge"
else
    echo "VERDICT: BLOCK — do not merge without manual review"
fi

git checkout - 2>/dev/null || true
git branch -D "$AUDIT_BRANCH" 2>/dev/null || true

[ "$AUDIT_PASS" = true ]
