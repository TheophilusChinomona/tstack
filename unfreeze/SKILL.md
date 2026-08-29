---
name: unfreeze
version: 0.1.0
description: Clear the freeze boundary set by freeze, allowing edits to all directories again. (tstack)
triggers:
  - unfreeze edits
  - unlock all directories
  - remove edit restrictions
allowed-tools:
  - Bash
  - Read
---

## When to invoke this skill

Use when you want to widen edit scope without ending the session.
Use when asked to "unfreeze", "unlock edits", "remove freeze", or
"allow all edits".

# unfreeze — Clear Freeze Boundary

Remove the edit restriction set by `freeze`, allowing edits to all directories.

```bash
mkdir -p ./docs/analytics
echo '{"skill":"unfreeze","ts":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","repo":"'$(basename "$(git rev-parse --show-toplevel 2>/dev/null)" 2>/dev/null || echo "unknown")'"}'  >> ./docs/analytics/skill-usage.jsonl 2>/dev/null || true
```

## Clear the boundary

```bash
eval "$()"
STATE_DIR="$GSTACK_STATE_ROOT"
if [ -f "$STATE_DIRfreeze-dir.txt" ]; then
  PREV=$(cat "$STATE_DIRfreeze-dir.txt")
  rm -f "$STATE_DIRfreeze-dir.txt"
  echo "Freeze boundary cleared (was: $PREV). Edits are now allowed everywhere."
else
  echo "No freeze boundary was set."
fi
```

Tell the user the result. Note that `freeze` hooks are still registered for the
session — they will just allow everything since no state file exists. To re-freeze,
run `freeze` again.
