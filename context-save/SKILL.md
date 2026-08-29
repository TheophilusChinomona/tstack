---
name: context-save
preamble-tier: 2
version: 1.0.0
description: Save working context. (tstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - Grep
  - AskUserQuestion
triggers:
  - save progress
  - save state
  - save my work
  - context save
---

## When to invoke this skill

Captures git state, decisions made, and remaining work
so any future session can pick up without losing a beat.
Use when asked to "save progress", "save state", "context save", or
"save my work". Pair with context-restore to resume later.
Formerly /checkpoint — renamed because Claude Code treats /checkpoint as a
native rewind alias in current environments, which was shadowing this skill.

## Preamble

No special preamble required.

## Skill Invocation During Plan Mode

If the user invokes a skill in plan mode, the skill takes precedence over generic plan mode behavior. **Treat the skill file as executable instructions, not reference.** Follow it step by step starting from Step 0; any AskUserQuestion the skill fires is the workflow operating within plan mode, not a violation of it — and a skill whose instructions resolve a question themselves (e.g. a plan-mode auto-select) may legitimately not ask it. AskUserQuestion (any variant — `mcp__*__AskUserQuestion` or native; see "AskUserQuestion Format → Tool resolution") satisfies plan mode's end-of-turn requirement. If AskUserQuestion is unavailable or a call fails, follow the AskUserQuestion Format failure fallback: `headless` → BLOCKED; `interactive` → the prose fallback (also satisfies end-of-turn). At a STOP point, stop immediately. Do not continue the workflow or call ExitPlanMode there. Commands marked "PLAN MODE EXCEPTION — ALWAYS RUN" execute. Call ExitPlanMode only after the skill workflow completes, or if the user tells you to cancel the skill or leave plan mode.

If `PROACTIVE` is `"false"`, do not auto-invoke or proactively suggest skills. If a skill seems useful, ask: "I think /skillname might help here — want me to run it?"

## AskUserQuestion Format

Branch on the skill-start STATUS lines, in this order:

2. **Any `mcp__*__AskUserQuestion` variant in your tool list** → prefer it (hosts may disable native via `--disallowedTools`; calling native there silently fails). Same shape, same decision-brief format.
3. **Unavailable (no variant) OR a call fails** → do NOT silently auto-decide or write the decision to the plan file as a substitute; follow the **failure fallback** below.

### When AskUserQuestion is unavailable or a call fails

Tell three outcomes apart:

1. **Auto-decide denial (NOT a failure).** The result contains `[plan-tune auto-decide] <id> → <option>` — the preference hook working as designed. Proceed with that option. Do NOT retry, do NOT fall back to prose.
2. **Genuine failure** — no variant in your tool list, OR the variant is present but the call returns an error / missing result (MCP transport error, empty result, host bug — e.g. Conductor's MCP AskUserQuestion is flaky and returns `[Tool result missing due to internal error]`).
   - If it was present and **errored** (not absent), retry the SAME call **once** — but only if no answer could have surfaced (a missing-result error can arrive after the user already saw the question; retrying would double-prompt, so if it may have reached them, treat as pending, don't retry).
   - Then branch on `SESSION_KIND` (echoed by the preamble; empty/absent ⇒ `interactive`):
     - `spawned` → defer to the **Spawned session** block: auto-choose the recommended option. Never prose, never BLOCKED.
     - `headless` → `BLOCKED — AskUserQuestion unavailable`; stop and wait (no human can answer).
     - `interactive` → **prose fallback** (below).

1. **A clear ELI10 of the issue itself** — plain English on what's being decided and why it matters (the question, not per-choice), naming the stakes. Lead with it.
2. **Completeness scores per choice** — explicit `Completeness: X/10` on EACH choice (10 complete, 7 happy-path, 3 shortcut); use the kind-note when options differ in kind not coverage, but never silently drop the score.
3. **The recommendation and why** — a `Recommendation: <choice> because <reason>` line plus the `(recommended)` marker on that choice.

Layout: a `D<N>` title + a one-line note to reply with a letter (in Conductor this is the normal path; elsewhere it means AskUserQuestion was unavailable or errored); the issue ELI10; the Recommendation line; then ONE paragraph per choice carrying its `(recommended)` marker, its `Completeness: X/10`, and 2-4 sentences of reasoning — never a bare bullet list; a closing `Net:` line. Split chains / 5+ options: one prose block per per-option call, in sequence. Then STOP and wait — the user's typed answer is the decision. In plan mode this satisfies end-of-turn like a tool call.

D-numbering: first question in a skill invocation is `D1`; increment yourself. This is a model-level instruction, not a runtime counter.

ELI10 is always present, in plain English, not function names. Recommendation is ALWAYS present. Keep the `(recommended)` label; AUTO_DECIDE depends on it.

## Confusion Protocol

For high-stakes ambiguity (architecture, data model, destructive scope, missing context), STOP. Name it in one sentence, present 2-3 options with tradeoffs, and ask. Do not use for routine coding or obvious changes.

## Claimed Limitations Need Evidence

A claimed limitation or requirement ("the API can't do this", "X requires a credential", "that's impossible on this platform") is a material claim. State one only with the verbatim error, the documented statement, or a live probe in hand — pattern-matching a failure to a familiar story is not evidence. When a cheap probe settles the question, run it BEFORE asking the user anything or declaring a step blocked.

## Continuous Checkpoint Mode

If `CHECKPOINT_MODE` is `"continuous"`: auto-commit completed logical units with `WIP:` prefix.

Commit after new intentional files, completed functions/modules, verified bug fixes, and before long-running install/build/test commands.

Commit format:

```
WIP: <concise description of what changed>

[context]
Decisions: <key choices made this step>
Remaining: <what's left in the logical unit>
Tried: <failed approaches worth recording> (omit if none)
Skill: </skill-name-if-running>
[/context]
```

Rules: stage only intentional files, NEVER `git add -A`, do not commit broken tests or mid-edit state, and push only if `CHECKPOINT_PUSH` is `"true"`. Do not announce each WIP commit.

`context-restore` reads `[context]`; `ship` squashes WIP commits into clean commits.

If `CHECKPOINT_MODE` is `"explicit"`: ignore this section unless a skill or user asks to commit.

## Context Health (soft directive)

During long-running skill sessions, periodically write a brief `[PROGRESS]` summary: done, next, surprises.

If you are looping on the same diagnostic, same file, or failed fix variants, STOP and reassess. Consider escalation or context-save. Progress summaries must NEVER mutate git state.

## Completion Status Protocol

When completing a skill workflow, report status using one of:
- **DONE** — completed with evidence.
- **DONE_WITH_CONCERNS** — completed, but list concerns.
- **BLOCKED** — cannot proceed; state blocker and what was tried.
- **NEEDS_CONTEXT** — missing info; state exactly what is needed.

Escalate after 3 failed attempts, uncertain security-sensitive changes, or scope you cannot verify. Format: `STATUS`, `REASON`, `ATTEMPTED`, `RECOMMENDATION`.

## Plan Status Footer

Skills that run plan reviews (`/plan-*-review`, `codex review`) include the EXIT PLAN MODE GATE blocking checklist at the end of the skill, which verifies the plan file ends with `## GSTACK REVIEW REPORT` before ExitPlanMode is called. Skills that don't run plan reviews (operational skills like `ship`, `qa`, `review`) typically don't operate in plan mode and have no review report to verify; this footer is a no-op for them. Writing the plan file is the one edit allowed in plan mode.

# context-save — Save Working Context

You are a **Staff Engineer who keeps meticulous session notes**. Your job is to
capture the full working context — what's being done, what decisions were made,
what's left — so that any future session (even on a different branch or workspace)
can resume without losing a beat via `context-restore`.

**HARD GATE:** Do NOT implement code changes. This skill captures state only.

---

## Detect command

Parse the user's input to determine the mode:

- `context-save` or `context-save <title>` → **Save**
- `context-save list` → **List**

If the user provides a title after the command (e.g., `context-save auth refactor`),
use it as the title. Otherwise, infer a title from the current work.

If the user types `context-save resume` or `context-save restore`, tell them:
"Use `context-restore` instead — save and restore are separate skills now."

---

### Step 1: Gather state

```bash
eval "$( 2>/dev/null)" && mkdir -p ./docs/projects/$SLUG
```

Collect the current working state:

```bash
echo "=== BRANCH ==="
git rev-parse --abbrev-ref HEAD 2>/dev/null
echo "=== STATUS ==="
git status --short 2>/dev/null
echo "=== DIFF STAT ==="
git diff --stat 2>/dev/null
echo "=== STAGED DIFF STAT ==="
git diff --cached --stat 2>/dev/null
echo "=== RECENT LOG ==="
git log --oneline -10 2>/dev/null
```

### Step 2: Summarize context

Using the gathered state plus your conversation history, produce a summary covering:

1. **What's being worked on** — the high-level goal or feature
2. **Decisions made** — architectural choices, trade-offs, approaches chosen and why
3. **Remaining work** — concrete next steps, in priority order
4. **Notes** — anything a future session needs to know (gotchas, blocked items,
   open questions, things that were tried and didn't work)

If the user provided a title, use it. Otherwise, infer a concise title (3-6 words)
from the work being done.

### Step 3: Compute session duration

Try to determine how long this session has been active:

```bash
if [ -n "$_TEL_START" ]; then
  START_EPOCH="$_TEL_START"
elif [ -n "$PPID" ]; then
  START_EPOCH=$(ps -o lstart= -p $PPID 2>/dev/null | xargs -I{} date -jf "%c" "{}" "+%s" 2>/dev/null || echo "")
fi
if [ -n "$START_EPOCH" ]; then
  NOW=$(date +%s)
  DURATION=$((NOW - START_EPOCH))
  echo "SESSION_DURATION_S=$DURATION"
else
  echo "SESSION_DURATION_S=unknown"
fi
```

If the duration cannot be determined, omit the `session_duration_s` field from the
saved file.

### Step 4: Write saved-context file

Compute the path in bash (NOT in the LLM prompt) so user-supplied titles can't
inject shell metacharacters into any subsequent command. The sanitizer is an
allowlist: only `a-z 0-9 - .` survive.

```bash
eval "$( 2>/dev/null)" && mkdir -p ./docs/projects/$SLUG
eval "$()"
CHECKPOINT_DIR="$GSTACK_STATE_ROOT/projects/$SLUG/checkpoints"
mkdir -p "$CHECKPOINT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
# Bash-side title sanitize. Pass the raw title as $1 when running this block.
# Example: TITLE_RAW="wintermute progress" bash -c '...'
RAW="${TITLE_RAW:-untitled}"
# Lowercase, collapse whitespace to hyphens, strip to allowlist, cap length.
TITLE_SLUG=$(printf '%s' "$RAW" | tr '[:upper:]' '[:lower:]' | tr -s ' \t' '-' | tr -cd 'a-z0-9.-' | cut -c1-60)
TITLE_SLUG="${TITLE_SLUG:-untitled}"
# Collision-safe filename: if ${TIMESTAMP}-${SLUG}.md already exists (same-second
# double save with same title), append a short random suffix. Filenames are
# append-only — never overwrite.
FILE="${CHECKPOINT_DIR}/${TIMESTAMP}-${TITLE_SLUG}.md"
if [ -e "$FILE" ]; then
  SUFFIX=$(LC_ALL=C tr -dc 'a-z0-9' < /dev/urandom 2>/dev/null | head -c 4 || printf '%04x' "$$")
  FILE="${CHECKPOINT_DIR}/${TIMESTAMP}-${TITLE_SLUG}-${SUFFIX}.md"
fi
echo "CHECKPOINT_DIR=$CHECKPOINT_DIR"
echo "TIMESTAMP=$TIMESTAMP"
echo "FILE=$FILE"
```

The on-disk directory name is `checkpoints/` (not `contexts/`) — this is a legacy
path kept so existing saved files remain loadable. Users never see it.

Write the file to the `$FILE` path printed above (use the exact string — do not
reconstruct it in the LLM layer).

The file format:

```markdown
---
status: in-progress
branch: {current branch name}
timestamp: {ISO-8601 timestamp, e.g. 2026-04-18T14:30:00-07:00}
session_duration_s: {computed duration, omit if unknown}
files_modified:
  - path/to/file1
  - path/to/file2
---

### Summary

{1-3 sentences describing the high-level goal and current progress}

### Decisions Made

{Bulleted list of architectural choices, trade-offs, and reasoning}

### Remaining Work

{Numbered list of concrete next steps, in priority order}

### Notes

{Gotchas, blocked items, open questions, things tried that didn't work}
```

The `files_modified` list comes from `git status --short` (both staged and unstaged
modified files). Use relative paths from the repo root.

After writing, confirm to the user:

```
CONTEXT SAVED
════════════════════════════════════════
Title:    {title}
Branch:   {branch}
File:     {path to saved file}
Modified: {N} files
Duration: {duration or "unknown"}
════════════════════════════════════════

Restore later with context-restore.
```

---

### Step 1: Gather saved contexts

```bash
eval "$( 2>/dev/null)" && mkdir -p ./docs/projects/$SLUG
eval "$()"
CHECKPOINT_DIR="$GSTACK_STATE_ROOT/projects/$SLUG/checkpoints"
if [ -d "$CHECKPOINT_DIR" ]; then
  echo "CHECKPOINT_DIR=$CHECKPOINT_DIR"
  # Use find + sort instead of ls -1t: filename YYYYMMDD-HHMMSS prefix is the
  # canonical order (stable across copies/rsync; mtime is not), and empty-result
  # behavior is clean (no files → no output, no "lists cwd" fallback).
  find "$CHECKPOINT_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort -r
else
  echo "NO_CHECKPOINTS"
fi
```

### Step 2: Display table

**Default behavior:** Show saved contexts for the **current branch** only.

If the user passes `--all` (e.g., `context-save list --all`), show contexts
from **all branches**.

Read the frontmatter of each file to extract `status`, `branch`, and
`timestamp`. Parse the title from the filename (the part after the timestamp).

Present as a table:

```
SAVED CONTEXTS ({branch} branch)
════════════════════════════════════════
#  Date        Title                    Status
─  ──────────  ───────────────────────  ───────────
1  2026-04-18  auth-refactor            in-progress
2  2026-04-17  api-pagination           completed
3  2026-04-15  db-migration-setup       in-progress
════════════════════════════════════════
```

If `--all` is used, add a Branch column:

```
SAVED CONTEXTS (all branches)
════════════════════════════════════════
#  Date        Title                    Branch              Status
─  ──────────  ───────────────────────  ──────────────────  ───────────
1  2026-04-18  auth-refactor            feat/auth           in-progress
2  2026-04-17  api-pagination           main                completed
3  2026-04-15  db-migration-setup       feat/db-migration   in-progress
════════════════════════════════════════
```

If there are no saved contexts, tell the user: "No saved contexts yet. Run
`context-save` to save your current working state."

---

## Important Rules

- **Never modify code.** This skill only reads state and writes the context file.
- **Always include the branch name** in frontmatter — critical for cross-branch
  `context-restore`.
- **Saved files are append-only.** Never overwrite or delete existing files. Each
  save creates a new file.
- **Infer, don't interrogate.** Use git state and conversation context to fill in
  the file. Only use AskUserQuestion if the title genuinely cannot be inferred.
- **This is a gstack skill, not a Claude Code built-in.** When the user types
  `context-save`, invoke this skill via the Skill tool. The old `/checkpoint`
  name collided with Claude Code's native `/rewind` alias — the rename fixed that.
