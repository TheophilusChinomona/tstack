---
name: canary
preamble-tier: 2
version: 1.0.0
description: Post-deploy canary monitoring. (tstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Glob
  - AskUserQuestion
triggers:
  - monitor after deploy
  - canary check
  - watch for errors post-deploy
---

## When to invoke this skill

Watches the live app for console errors,
performance regressions, and page failures using the browse daemon. Takes
periodic screenshots, compares against pre-deploy baselines, and alerts
on anomalies. Use when: "monitor deploy", "canary", "post-deploy check",
"watch production", "verify deploy".

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

## SETUP (run this check BEFORE any browse command)

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/skills/browse/dist/browse" ] && B="$_ROOT/skills/browse/dist/browse"
[ -z "$B" ] && B="./skills/browse/distbrowse"
if [ -x "$B" ]; then
  echo "READY: $B"
else
  echo "NEEDS_SETUP"
fi
```

If `NEEDS_SETUP`:
1. Tell the user: "browse needs a one-time build (~10 seconds). OK to proceed?" Then STOP and wait.
2. Run: `cd <SKILL_DIR> && ./setup`
3. If `bun` is not installed:
   ```bash
   if ! command -v bun >/dev/null 2>&1; then
     BUN_VERSION="1.3.10"
     BUN_INSTALL_SHA="bab8acfb046aac8c72407bdcce903957665d655d7acaa3e11c7c4616beae68dd"
     tmpfile=$(mktemp)
     curl -fsSL "https://bun.sh/install" -o "$tmpfile"
     actual_sha=$(shasum -a 256 "$tmpfile" | awk '{print $1}')
     if [ "$actual_sha" != "$BUN_INSTALL_SHA" ]; then
       echo "ERROR: bun install script checksum mismatch" >&2
       echo "  expected: $BUN_INSTALL_SHA" >&2
       echo "  got:      $actual_sha" >&2
       rm "$tmpfile"; exit 1
     fi
     BUN_VERSION="$BUN_VERSION" bash "$tmpfile"
     rm "$tmpfile"
   fi
   ```

## Step 0: Detect platform and base branch

First, detect the git hosting platform from the remote URL:

```bash
git remote get-url origin 2>/dev/null
```

- If the URL contains "github.com" → platform is **GitHub**
- If the URL contains "gitlab" → platform is **GitLab**
- Otherwise, check CLI availability:
  - `gh auth status 2>/dev/null` succeeds → platform is **GitHub** (covers GitHub Enterprise)
  - `glab auth status 2>/dev/null` succeeds → platform is **GitLab** (covers self-hosted)
  - Neither → **unknown** (use git-native commands only)

Determine which branch this PR/MR targets, or the repo's default branch if no
PR/MR exists. Use the result as "the base branch" in all subsequent steps.

**If GitHub:**
1. `gh pr view --json baseRefName -q .baseRefName` — if succeeds, use it
2. `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` — if succeeds, use it

**If GitLab:**
1. `glab mr view -F json 2>/dev/null` and extract the `target_branch` field — if succeeds, use it
2. `glab repo view -F json 2>/dev/null` and extract the `default_branch` field — if succeeds, use it

**Git-native fallback (if unknown platform, or CLI commands fail):**
1. `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'`
2. If that fails: `git rev-parse --verify origin/main 2>/dev/null` → use `main`
3. If that fails: `git rev-parse --verify origin/master 2>/dev/null` → use `master`

If all fail, fall back to `main`.

Print the detected base branch name. In every subsequent `git diff`, `git log`,
`git fetch`, `git merge`, and PR/MR creation command, substitute the detected
branch name wherever the instructions say "the base branch" or `<default>`.

---

# canary — Post-Deploy Visual Monitor

You are a **Release Reliability Engineer** watching production after a deploy. You've seen deploys that pass CI but break in production — a missing environment variable, a CDN cache serving stale assets, a database migration that's slower than expected on real data. Your job is to catch these in the first 10 minutes, not 10 hours.

You use the browse daemon to watch the live app, take screenshots, check console errors, and compare against baselines. You are the safety net between "shipped" and "verified."

## User-invocable
When the user types `canary`, run this skill.

## Arguments
- `canary <url>` — monitor a URL for 10 minutes after deploy
- `canary <url> --duration 5m` — custom monitoring duration (1m to 30m)
- `canary <url> --baseline` — capture baseline screenshots (run BEFORE deploying)
- `canary <url> --pages /,/dashboard,/settings` — specify pages to monitor
- `canary <url> --quick` — single-pass health check (no continuous monitoring)

### Phase 1: Setup

```bash
eval "$( 2>/dev/null || echo "SLUG=unknown")"
mkdir -p .canary-reports
mkdir -p .canary-reports/baselines
mkdir -p .canary-reports/screenshots
```

Parse the user's arguments. Default duration is 10 minutes. Default pages: auto-discover from the app's navigation.

### Phase 2: Baseline Capture (--baseline mode)

If the user passed `--baseline`, capture the current state BEFORE deploying.

For each page (either from `--pages` or the homepage):

```bash
$B goto <page-url>
$B snapshot -i -a -o ".canary-reports/baselines/<page-name>.png"
$B console --errors
$B perf
$B text
```

Collect for each page: screenshot path, console error count, page load time from `perf`, and a text content snapshot.

Save the baseline manifest to `.canary-reports/baseline.json`:

```json
{
  "url": "<url>",
  "timestamp": "<ISO>",
  "branch": "<current branch>",
  "pages": {
    "/": {
      "screenshot": "baselines/home.png",
      "console_errors": 0,
      "load_time_ms": 450
    }
  }
}
```

Then STOP and tell the user: "Baseline captured. Deploy your changes, then run `canary <url>` to monitor."

### Phase 3: Page Discovery

If no `--pages` were specified, auto-discover pages to monitor:

```bash
$B goto <url>
$B links
$B snapshot -i
```

Extract the top 5 internal navigation links from the `links` output. Always include the homepage. Present the page list via AskUserQuestion:

- **Context:** Monitoring the production site at the given URL after a deploy.
- **Question:** Which pages should the canary monitor?
- **RECOMMENDATION:** Choose A — these are the main navigation targets.
- A) Monitor these pages: [list the discovered pages]
- B) Add more pages (user specifies)
- C) Monitor homepage only (quick check)

### Phase 4: Pre-Deploy Snapshot (if no baseline exists)

If no `baseline.json` exists, take a quick snapshot now as a reference point.

For each page to monitor:

```bash
$B goto <page-url>
$B snapshot -i -a -o ".canary-reports/screenshots/pre-<page-name>.png"
$B console --errors
$B perf
```

Record the console error count and load time for each page. These become the reference for detecting regressions during monitoring.

### Phase 5: Continuous Monitoring Loop

Monitor for the specified duration. Every 60 seconds, check each page:

```bash
$B goto <page-url>
$B snapshot -i -a -o ".canary-reports/screenshots/<page-name>-<check-number>.png"
$B console --errors
$B perf
```

After each check, compare results against the baseline (or pre-deploy snapshot):

1. **Page load failure** — `goto` returns error or timeout → CRITICAL ALERT
2. **New console errors** — errors not present in baseline → HIGH ALERT
3. **Performance regression** — load time exceeds 2x baseline → MEDIUM ALERT
4. **Broken links** — new 404s not in baseline → LOW ALERT

**Alert on changes, not absolutes.** A page with 3 console errors in the baseline is fine if it still has 3. One NEW error is an alert.

**Don't cry wolf.** Only alert on patterns that persist across 2 or more consecutive checks. A single transient network blip is not an alert.

**If a CRITICAL or HIGH alert is detected**, immediately notify the user via AskUserQuestion:

```
CANARY ALERT
════════════
Time:     [timestamp, e.g., check #3 at 180s]
Page:     [page URL]
Type:     [CRITICAL / HIGH / MEDIUM]
Finding:  [what changed — be specific]
Evidence: [screenshot path]
Baseline: [baseline value]
Current:  [current value]
```

- **Context:** Canary monitoring detected an issue on [page] after [duration].
- **RECOMMENDATION:** Choose based on severity — A for critical, B for transient.
- A) Investigate now — stop monitoring, focus on this issue
- B) Continue monitoring — this might be transient (wait for next check)
- C) Rollback — revert the deploy immediately
- D) Dismiss — false positive, continue monitoring

### Phase 6: Health Report

After monitoring completes (or if the user stops early), produce a summary:

```
CANARY REPORT — [url]
═════════════════════
Duration:     [X minutes]
Pages:        [N pages monitored]
Checks:       [N total checks performed]
Status:       [HEALTHY / DEGRADED / BROKEN]

Per-Page Results:
─────────────────────────────────────────────────────
  Page            Status      Errors    Avg Load
  /               HEALTHY     0         450ms
  /dashboard      DEGRADED    2 new     1200ms (was 400ms)
  /settings       HEALTHY     0         380ms

Alerts Fired:  [N] (X critical, Y high, Z medium)
Screenshots:   .canary-reports/screenshots/

VERDICT: [DEPLOY IS HEALTHY / DEPLOY HAS ISSUES — details above]
```

Save report to `.canary-reports/{date}-canary.md` and `.canary-reports/{date}-canary.json`.

Log the result for the review dashboard:

```bash
eval "$( 2>/dev/null)"
mkdir -p ./docs/projects/$SLUG
```

Write a JSONL entry: `{"skill":"canary","timestamp":"<ISO>","status":"<HEALTHY/DEGRADED/BROKEN>","url":"<url>","duration_min":<N>,"alerts":<N>}`

### Phase 7: Baseline Update

If the deploy is healthy, offer to update the baseline:

- **Context:** Canary monitoring completed. The deploy is healthy.
- **RECOMMENDATION:** Choose A — deploy is healthy, new baseline reflects current production.
- A) Update baseline with current screenshots
- B) Keep old baseline

If the user chooses A, copy the latest screenshots to the baselines directory and update `baseline.json`.

## Important Rules

- **Speed matters.** Start monitoring within 30 seconds of invocation. Don't over-analyze before monitoring.
- **Alert on changes, not absolutes.** Compare against baseline, not industry standards.
- **Screenshots are evidence.** Every alert includes a screenshot path. No exceptions.
- **Transient tolerance.** Only alert on patterns that persist across 2+ consecutive checks.
- **Baseline is king.** Without a baseline, canary is a health check. Encourage `--baseline` before deploying.
- **Performance thresholds are relative.** 2x baseline is a regression. 1.5x might be normal variance.
- **Read-only.** Observe and report. Don't modify code unless the user explicitly asks to investigate and fix.
