---
name: tstack-upgrade
version: 2.0.0
description: Auto-upgrade tstack skills with snooze, changelog, and daemon management.
triggers:
  - upgrade tstack
  - update tstack
  - check for updates
  - get latest tstack
allowed-tools:
  - Bash
  - Read
  - Write
  - AskUserQuestion
---

# tstack-upgrade

Upgrade tstack to the latest version and show what's new.

## When to invoke

- User says "upgrade tstack", "update tstack", "check for updates"
- Periodic update check (if enabled)
- After a fresh clone, to check if updates are available

## Configuration

| Setting | Default | Description |
|---------|---------|-------------|
| `TSTACK_AUTO_UPGRADE` | unset | Set to `1` to skip prompts |
| `TSTACK_UPDATE_CHECK` | `true` | Set to `false` to disable checks |
| `TSTACK_TEAM_MODE` | `false` | If true, remove local vendored copies |

Config is read from `./tstack.yaml` if it exists.

## Step 1: Check if update check is enabled

```bash
_UPDATE_CHECK="${TSTACK_UPDATE_CHECK:-true}"
if [ "$_UPDATE_CHECK" = "false" ]; then
  echo "UPDATE_CHECK_DISABLED"
else
  echo "UPDATE_CHECK_ENABLED"
fi
```

If `UPDATE_CHECK_DISABLED`, skip the upgrade check and continue with the current skill.

## Step 2: Detect install type

```bash
if [ -d "./.git" ]; then
  INSTALL_TYPE="global-git"
  INSTALL_DIR="$(pwd)"
elif [ -d "./docs/repos/.git" ]; then
  INSTALL_TYPE="global-git"
  INSTALL_DIR="$(pwd)/docs/repos/tstack"
elif [ -d ".claude/skills/.git" ]; then
  INSTALL_TYPE="local-git"
  INSTALL_DIR="$(cd .claude/skills/tstack 2>/dev/null && pwd)"
elif [ -d ".agents/skills/.git" ]; then
  INSTALL_TYPE="local-git"
  INSTALL_DIR="$(cd .agents/skills/tstack 2>/dev/null && pwd)"
elif [ -d ".claude/skills/tstack" ]; then
  INSTALL_TYPE="vendored"
  INSTALL_DIR="$(cd .claude/skills/tstack && pwd)"
elif [ -d ".agents/skills/tstack" ]; then
  INSTALL_TYPE="vendored"
  INSTALL_DIR="$(cd .agents/skills/tstack && pwd)"
else
  INSTALL_TYPE="vendored-global"
  INSTALL_DIR="$(pwd)"
fi
echo "Install type: $INSTALL_TYPE at $INSTALL_DIR"
```

## Step 3: Get current + remote version

```bash
CURRENT_VERSION=$(cat "$INSTALL_DIR/VERSION" 2>/dev/null | tr -d '[:space:]' || echo "unknown")

# For git installs, fetch remote version
if [ "$INSTALL_TYPE" = "global-git" ] || [ "$INSTALL_TYPE" = "local-git" ]; then
  cd "$INSTALL_DIR"
  git fetch origin main --quiet 2>/dev/null
  REMOTE_VERSION=$(git show origin/main:VERSION 2>/dev/null | tr -d '[:space:]' || echo "$CURRENT_VERSION")
else
  # For vendored installs, check the remote repo
  REMOTE_VERSION=$(curl -fsSL https://raw.githubusercontent.com/TheophilusChinomona/tstack/main/VERSION 2>/dev/null | tr -d '[:space:]' || echo "$CURRENT_VERSION")
fi

echo "CURRENT=$CURRENT_VERSION REMOTE=$REMOTE_VERSION"
```

## Step 4: Compare versions

```bash
if [ "$CURRENT_VERSION" = "$REMOTE_VERSION" ] || [ "$REMOTE_VERSION" = "" ]; then
  echo "UP_TO_DATE"
else
  echo "UPGRADE_AVAILABLE $CURRENT_VERSION $REMOTE_VERSION"
fi
```

If `UP_TO_DATE`, tell the user "You're on the latest version (v{CURRENT_VERSION})." and continue.

## Step 5: Handle upgrade decision

### Auto-upgrade check

```bash
_AUTO="${TSTACK_AUTO_UPGRADE:-}"
_SNOOZE_FILE="$INSTALL_DIR/.tstack/update-snoozed"

# Check snooze state
if [ -f "$_SNOOZE_FILE" ]; then
  _SNOOZED_VER=$(awk '{print $1}' "$_SNOOZE_FILE")
  _SNOOZE_LEVEL=$(awk '{print $2}' "$_SNOOZE_FILE")
  _SNOOZE_TIME=$(awk '{print $3}' "$_SNOOZE_FILE")
  
  if [ "$_SNOOZED_VER" = "$REMOTE_VERSION" ]; then
    _NOW=$(date +%s)
    case "$_SNOOZE_LEVEL" in
      1) _BACKOFF=86400 ;;   # 24h
      2) _BACKOFF=172800 ;;  # 48h
      *) _BACKOFF=604800 ;;  # 1 week
    esac
    if [ $((_NOW - _SNOOZE_TIME)) -lt "$_BACKOFF" ]; then
      echo "SNOOZED"
    fi
  fi
fi
```

### If auto-enabled

If `$_AUTO` is `1` or `true`, skip the prompt and proceed to Step 6.

### If snoozed

If `SNOOZED`, continue with the current skill without mentioning the upgrade.

### AskUserQuestion

```
Question: "tstack v{REMOTE_VERSION} is available (you're on v{CURRENT_VERSION}). Upgrade now?"

Options:
- "Yes, upgrade now"
- "Always keep me up to date"
- "Not now"
- "Never ask again"
```

**If "Yes, upgrade now":** Proceed to Step 6.

**If "Always keep me up to date":**
```bash
mkdir -p "$INSTALL_DIR/.tstack"
echo "auto_upgrade: true" > "$INSTALL_DIR/.tstack/config.yaml"
```
Tell user: "Auto-upgrade enabled." Then proceed.

**If "Not now":**
```bash
mkdir -p "$INSTALL_DIR/.tstack"
_SNOOZE_LEVEL=1
if [ -f "$_SNOOZE_FILE" ]; then
  _SNOOZED_VER=$(awk '{print $1}' "$_SNOOZE_FILE")
  if [ "$_SNOOZED_VER" = "$REMOTE_VERSION" ]; then
    _CUR=$(awk '{print $2}' "$_SNOOZE_FILE")
    _SNOOZE_LEVEL=$((_CUR + 1))
    [ "$_SNOOZE_LEVEL" -gt 3 ] && _SNOOZE_LEVEL=3
  fi
fi
echo "$REMOTE_VERSION $_SNOOZE_LEVEL $(date +%s)" > "$_SNOOZE_FILE"
```
Tell user: "Next reminder in 24h (or 48h or 1 week)." Then continue.

**If "Never ask again":**
```bash
mkdir -p "$INSTALL_DIR/.tstack"
echo "update_check: false" > "$INSTALL_DIR/.tstack/config.yaml"
```
Tell user: "Update checks disabled." Then continue.

## Step 6: Stop browse daemon

```bash
_BROWSE_STATE="${BROWSE_STATE_FILE:-$INSTALL_DIR/.browse.json}"
if [ -f "$_BROWSE_STATE" ]; then
  DAEMON_PID=$(grep -o '"pid":[0-9]*' "$_BROWSE_STATE" | head -1 | cut -d: -f2)
  if [ -n "$DAEMON_PID" ] && kill -0 "$DAEMON_PID" 2>/dev/null; then
    echo "Stopping browse daemon (pid=$DAEMON_PID)..."
    "$INSTALL_DIR/skills/browse/dist/browse" stop 2>/dev/null || true
  fi
fi
```

## Step 7: Perform upgrade

### For git installs

```bash
cd "$INSTALL_DIR"
# Discard regenerable generated files
git checkout -- 'SKILL.md' '*/SKILL.md' '*/sections/*.md' 2>/dev/null || true
git fetch origin main
git pull --ff-only --autostash origin main
```

If ff-only fails:
1. Check `git status --porcelain` and `git rev-list origin/main..HEAD --oneline`
2. If both empty: safe to reset
3. Otherwise: AskUserQuestion listing what will be lost

```bash
# If safe to proceed:
git stash
git reset --hard origin/main
```

### For vendored installs

```bash
PARENT=$(dirname "$INSTALL_DIR")
TMP_DIR=$(mktemp -d)
git clone --depth 1 https://github.com/TheophilusChinomona/tstack.git "$TMP_DIR/tstack"
mv "$INSTALL_DIR" "$INSTALL_DIR.bak"
mv "$TMP_DIR/tstack" "$INSTALL_DIR"
rm -rf "$INSTALL_DIR.bak" "$TMP_DIR"
```

### Run setup

```bash
cd "$INSTALL_DIR" && ./setup
```

## Step 8: Update local vendored copy (if applicable)

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
_LOCAL_GSTACK=""
if [ -n "$_ROOT" ] && [ -d "$_ROOT/.claude/skills/tstack" ]; then
  _RESOLVED_LOCAL=$(cd "$_ROOT/.claude/skills/tstack" && pwd -P)
  _RESOLVED_PRIMARY=$(cd "$INSTALL_DIR" && pwd -P)
  if [ "$_RESOLVED_LOCAL" != "$_RESOLVED_PRIMARY" ]; then
    _LOCAL_GSTACK="$_ROOT/.claude/skills/tstack"
  fi
fi

if [ -n "$_LOCAL_GSTACK" ]; then
  _TEAM_MODE="${TSTACK_TEAM_MODE:-false}"
  if [ "$_TEAM_MODE" = "true" ]; then
    cd "$_ROOT"
    git rm -r --cached .claude/skills/ 2>/dev/null || true
    grep -qF '.claude/skills/' .gitignore || echo '.claude/skills/' >> .gitignore
    rm -rf "$_LOCAL_GSTACK"
    echo "Removed vendored copy (team mode active)."
  else
    mv "$_LOCAL_GSTACK" "$_LOCAL_GSTACK.bak"
    cp -Rf "$INSTALL_DIR" "$_LOCAL_GSTACK"
    rm -rf "$_LOCAL_GSTACK/.git"
    cd "$_LOCAL_GSTACK" && ./setup
    rm -rf "$_LOCAL_GSTACK.bak"
    echo "Updated local vendored copy. Commit when ready."
  fi
fi
```

## Step 9: Write marker + clear cache

```bash
mkdir -p "$INSTALL_DIR/.tstack"
echo "$CURRENT_VERSION" > "$INSTALL_DIR/.tstack/just-upgraded-from"
rm -f "$INSTALL_DIR/.tstack/last-update-check"
rm -f "$INSTALL_DIR/.tstack/update-snoozed"
```

## Step 10: Show What's New

```bash
NEW_VERSION=$(cat "$INSTALL_DIR/VERSION" | tr -d '[:space:]')
```

Read `$INSTALL_DIR/CHANGELOG.md`. Find entries between `CURRENT_VERSION` and `NEW_VERSION`. Summarize 5-7 bullets grouped by theme.

```
tstack v{NEW_VERSION} — upgraded from v{CURRENT_VERSION}!

What's new:
- [bullet 1]
- [bullet 2]
- ...

Happy shipping!
```

## Step 11: Continue

After showing What's New, continue with whatever skill the user originally invoked.

## Periodic Check (for skills preamble)

When any skill runs, it can include this lightweight check in its preamble:

```bash
_UPDATE_CHECK="${TSTACK_UPDATE_CHECK:-true}"
if [ "$_UPDATE_CHECK" = "false" ]; then
  echo "SKIP"
else
  _STATE_DIR="${TSTACK_STATE_DIR:-./.tstack}"
  _NOW=$(date +%s)
  _LAST=$(cat "$_STATE_DIR/last-update-check" 2>/dev/null || echo 0)
  # Check once per hour
  if [ $((_NOW - _LAST)) -ge 3600 ]; then
    echo "$_NOW" > "$_STATE_DIR/last-update-check"
    # Trigger upgrade check (non-blocking)
    echo "CHECK_NOW"
  else
    echo "SKIP"
  fi
fi
```

If `CHECK_NOW`, run Steps 2-5 in the background. If upgrade is available and auto-upgrade is enabled, perform it silently. Otherwise, set a flag for the next skill invocation to surface the prompt.
