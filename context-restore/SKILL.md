---
name: context-restore
preamble-tier: 2
version: 1.0.0
description: Restore working context saved earlier by context-save. (tstack)
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
  - AskUserQuestion
triggers:
  - resume where i left off
  - restore context
  - where was i
  - pick up where i left off
  - context restore
---

## When to invoke this skill

Loads the most recent
saved state (preferring the current branch, falling back across branches) so
you can pick up where you left off — even across Conductor workspace handoffs.
Use when asked to "resume", "restore context", "where was I", or
"pick up where I left off". Pair with context-save.
Formerly /checkpoint resume — renamed because Claude Code treats /checkpoint
as a native rewind alias in current environments.

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

# context-restore — Restore Saved Working Context

You are a **Staff Engineer reading a colleague's meticulous session notes** to
pick up exactly where they left off. Your job is to load the most recent saved
context and present it clearly so the user can resume work without losing a beat.

**HARD GATE:** Do NOT implement code changes. This skill only reads saved
context files and presents the summary.

**Default: prefer the most recent checkpoint saved on the CURRENT branch; if
this branch has none, fall back to the most recent across ALL branches.** The
fallback is for Conductor workspace handoff — a context saved on one branch can
be resumed from another. The current-branch preference exists because every
worktree of a repo shares one checkpoints directory (same origin-derived slug),
so without it `context-restore` in one worktree could silently load a sibling
worktree's newer checkpoint.

**Do NOT hard-filter the candidate set to the current branch** — other-branch
checkpoints stay in the set as a fallback. They are just ordered *after* the
current branch's own, so a current-branch save is never shadowed by a newer
sibling-worktree save. (`context-save list` is the flow that hard-scopes to one
branch.)

---

## Detect command

Parse the user's input:

- `context-restore` → load the most recent saved context (any branch)
- `context-restore <title-fragment-or-number>` → load a specific saved context
- `context-restore list` → tell the user "Use `context-save list` — listing
  lives on the save side" and exit. No mode detection here.

---

### Step 1: Find saved contexts

```bash
eval "$( 2>/dev/null)" && mkdir -p ./docs/projects/$SLUG
eval "$()"
CHECKPOINT_DIR="$GSTACK_STATE_ROOT/projects/$SLUG/checkpoints"
if [ ! -d "$CHECKPOINT_DIR" ]; then
  echo "NO_CHECKPOINTS"
else
  # Use find + sort instead of ls -1t. Two reasons:
  # 1. Canonical order is the filename YYYYMMDD-HHMMSS prefix (stable across
  #    copies/rsync). Filesystem mtime drifts and is not authoritative.
  # 2. On macOS, `find ... | xargs ls -1t` with zero results falls back to
  #    listing cwd. `sort -r` on empty input cleanly returns nothing.
  # Scan the 200 newest so a current-branch checkpoint sitting below a burst of
  # sibling-worktree saves can still be found; the result is capped at 20 below.
  ALL=$(find "$CHECKPOINT_DIR" -maxdepth 1 -name "*.md" -type f 2>/dev/null | sort -r | head -200)
  if [ -z "$ALL" ]; then
    echo "NO_CHECKPOINTS"
  else
    # Order current-branch checkpoints first, other branches after. A git branch
    # is checked out in at most one worktree, and all worktrees of a repo share
    # one checkpoints dir (same origin-derived slug), so without this preference
    # `context-restore` in worktree A could load worktree B's newer checkpoint.
    # Cross-branch resume (Conductor handoff) is preserved as the fallback: when
    # the current branch has no checkpoint, the full newest-first set is used.
    # CURRENT_BRANCH may be pre-set (tests); otherwise resolve it from git.
    : "${CURRENT_BRANCH:=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)}"
    SAME=""; OTHER=""
    while IFS= read -r f; do
      [ -n "$f" ] || continue
      b=$(grep -m1 '^branch:' "$f" 2>/dev/null | sed 's/^branch:[[:space:]]*//')
      if [ -n "$CURRENT_BRANCH" ] && [ "$b" = "$CURRENT_BRANCH" ]; then
        SAME="${SAME}${f}
"
      else
        OTHER="${OTHER}${f}
"
      fi
    done <<EOF
$ALL
EOF
    # Cap at 20: a user with 10k saved files shouldn't blow the context window.
    FILES=$(printf '%s%s' "$SAME" "$OTHER" | grep -v '^[[:space:]]*$' | head -20)
    echo "$FILES"
  fi
fi
```

**Candidates include every `.md` file in the directory**, but they are ordered
**current-branch-first** (the branch is read from each file's `branch:`
frontmatter). Other-branch files stay in the set as a fallback, which preserves
Conductor workspace handoff when the current branch has no checkpoint of its own.

### Step 2: Load the right file

- If the user specified a title fragment or number: find the matching file among
  the candidates.
- Otherwise: load the **first file returned by Step 1 above** — that is the
  newest `YYYYMMDD-HHMMSS` checkpoint for the current branch, or, if the current
  branch has none, the newest across all branches.

Read the chosen file and present a summary:

```
RESUMING CONTEXT
════════════════════════════════════════
Title:       {title}
Branch:      {branch from frontmatter}
Saved:       {timestamp, human-readable}
Duration:    Last session was {formatted duration} (if available)
Status:      {status}
════════════════════════════════════════

### Summary
{summary from saved file}

### Remaining Work
{remaining work items}

### Notes
{notes}
```

If the current branch differs from the saved context's branch, note this:
"This context was saved on branch `{branch}`. You are currently on
`{current branch}`. You may want to switch branches before continuing."

### Step 3: Offer next steps

After presenting, ask via AskUserQuestion:

- A) Continue working on the remaining items
- B) Show the full saved file
- C) Just needed the context, thanks

If A, summarize the first remaining work item and suggest starting there.

---

## If no saved contexts exist

If Step 1 printed `NO_CHECKPOINTS`, tell the user:

"No saved contexts yet. Run `context-save` first to save your current working
state, then `context-restore` will find it."

---

## Important Rules

- **Never modify code.** This skill only reads saved files and presents them.
- **Prefer the current branch's own checkpoint, but keep all branches in the
  fallback set.** Cross-branch resume (Conductor handoff) still works when the
  current branch has no checkpoint; it just no longer lets a sibling worktree's
  newer save shadow this branch's own.
- **"Most recent" means the filename `YYYYMMDD-HHMMSS` prefix**, not
  `ls -1t` (filesystem mtime). Filenames are stable across file-system
  operations; mtime is not.
- **This is a gstack skill, not a Claude Code built-in.** When the user types
  `context-restore`, invoke this skill via the Skill tool.
