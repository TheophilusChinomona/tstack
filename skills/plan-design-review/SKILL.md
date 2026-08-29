---
name: plan-design-review
preamble-tier: 3
version: 2.0.0
description: Designer's eye plan review — interactive, like CEO and Eng review. (tstack)
allowed-tools:
  - Read
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
triggers:
  - design plan review
  - review ux plan
  - check design decisions
---

| When | Read this section |
|------|-------------------|
| running the 7 design passes, required outputs, and review report (only after Step 0 scope is agreed) | `sectionsreview-sections.md` |
---


### 0A. Initial Design Rating
Rate the plan's overall design completeness 0-10.
- "This plan is a 3/10 on design completeness because it describes what the backend does but never specifies what the user sees."
- "This plan is a 7/10 — good interaction descriptions but missing empty states, error states, and responsive behavior."

Explain what a 10 looks like for THIS plan.

### 0B. DESIGN.md Status
- If DESIGN.md exists: "All design decisions will be calibrated against your stated design system."
- If no DESIGN.md: "No design system found. Recommend running design-consultation first. Proceeding with universal design principles."

### 0C. Existing Design Leverage
What existing UI patterns, components, or design decisions in the codebase should this plan reuse? Don't reinvent what already works.

### 0D. Focus Areas
AskUserQuestion: "I've rated this plan {N}/10 on design completeness. The biggest gaps are {X, Y, Z}. I'll generate visual mockups next, then review all 7 dimensions. Want me to focus on specific areas instead of all 7?"

**STOP.** Do NOT proceed until user responds.

## Step 0.5: Visual Mockups (DEFAULT when DESIGN_READY)

If the plan involves any UI — screens, pages, components, visual changes — AND the
designer is available (`DESIGN_READY` was printed during setup), **generate
mockups immediately.** Do not ask permission. This is the default behavior.

Tell the user: "Generating visual mockups with the designer. This is how we
review design — real visuals, not text descriptions."

The ONLY time you skip mockups is when:
- `DESIGN_NOT_AVAILABLE` was printed (designer binary not found)
- The plan has zero UI scope (pure backend/API/infrastructure)

If the user explicitly says "skip mockups" or "text only", respect that. Otherwise, generate.

Allowed commands under this exception:
- `mkdir -p ./docs/projects/$SLUG/designs/...`
- `$D generate`, `$D variants`, `$D compare`, `$D iterate`, `$D evolve`, `$D check`
- `open` (fallback for viewing boards when `$B` is not available)

First, set up the output directory. Name it after the screen/feature being designed and today's date:

```bash
eval "$( 2>/dev/null)"
_DESIGN_DIR="./docs/plans/designs/<screen-name>-$(date +%Y%m%d)"
mkdir -p "$_DESIGN_DIR"
echo "DESIGN_DIR: $_DESIGN_DIR"
```

Replace `<screen-name>` with a descriptive kebab-case name (e.g., `homepage-variants`, `settings-page`, `onboarding-flow`).

**Generate mockups ONE AT A TIME in this skill.** The inline review flow generates
fewer variants and benefits from sequential control. Note: design-shotgun uses
parallel Agent subagents for variant generation, which works at Tier 2+ (15+ RPM).
The sequential constraint here is specific to plan-design-review's inline pattern.

For each UI screen/section in scope, construct a design brief from the plan's description (and DESIGN.md if present) and generate variants:

```bash
$D variants --brief "<description assembled from plan + DESIGN.md constraints>" --count 3 --output-dir "$_DESIGN_DIR/"
```

After generation, run a cross-model quality check on each variant:

```bash
$D check --image "$_DESIGN_DIR/variant-A.png" --brief "<the original brief>"
```

Flag any variants that fail the quality check. Offer to regenerate failures.

**Do NOT show variants inline via Read tool and ask for preferences.** Proceed
directly to the Comparison Board + Feedback Loop section below. The comparison board
IS the chooser — it has rating controls, comments, remix/regenerate, and structured
feedback output. Showing mockups inline is a degraded experience.

### Comparison Board + Feedback Loop

Create the comparison board and serve it over HTTP:

```bash
$D compare --images "$_DESIGN_DIR/variant-A.png,$_DESIGN_DIR/variant-B.png,$_DESIGN_DIR/variant-C.png" --output "$_DESIGN_DIR/design-board.html" --serve
```

This command generates the board HTML, starts an HTTP server on a random port,
and opens it in the user's default browser. **Run it in the background** with `&`
because the server needs to stay running while the user interacts with the board.

Parse the board URL from stderr output. Default daemon path:
`BOARD_URL: http://127.0.0.1:N/boards/<id>/` (already includes the per-board
path; use this for the AskUserQuestion URL AND as the base for the reload
endpoint). Legacy `--no-daemon` path emits `SERVE_STARTED: port=XXXXX` and
serves a single board at `/`, with reload at `/api/reload` — only relevant
when an external caller explicitly passes `--no-daemon`.

**PRIMARY WAIT: AskUserQuestion with board URL**

After the board is serving, use AskUserQuestion to wait for the user. Include the
board URL so they can click it if they lost the browser tab:

"I've opened a comparison board with the design variants:
<BOARD_URL> — Rate them, leave comments, remix
elements you like, and click Submit when you're done. Let me know when you've
submitted your feedback (or paste your preferences here). If you clicked
Regenerate or Remix on the board, tell me and I'll generate new variants."

Substitute `<BOARD_URL>` with the URL parsed from stderr (the daemon path
emits `BOARD_URL: http://127.0.0.1:N/boards/<id>/`).

**Do NOT use AskUserQuestion to ask which variant the user prefers.** The comparison
board IS the chooser. AskUserQuestion is just the blocking wait mechanism.

**After the user responds to AskUserQuestion:**

Check for feedback files next to the board HTML:
- `$_DESIGN_DIR/feedback.json` — written when user clicks Submit (final choice)
- `$_DESIGN_DIR/feedback-pending.json` — written when user clicks Regenerate/Remix/More Like This

```bash
if [ -f "$_DESIGN_DIR/feedback.json" ]; then
  echo "SUBMIT_RECEIVED"
  cat "$_DESIGN_DIR/feedback.json"
elif [ -f "$_DESIGN_DIR/feedback-pending.json" ]; then
  echo "REGENERATE_RECEIVED"
  cat "$_DESIGN_DIR/feedback-pending.json"
  rm "$_DESIGN_DIR/feedback-pending.json"
else
  echo "NO_FEEDBACK_FILE"
fi
```

The feedback JSON has this shape:
```json
{
  "preferred": "A",
  "ratings": { "A": 4, "B": 3, "C": 2 },
  "comments": { "A": "Love the spacing" },
  "overall": "Go with A, bigger CTA",
  "regenerated": false
}
```

**If `feedback.json` found:** The user clicked Submit on the board.
Read `preferred`, `ratings`, `comments`, `overall` from the JSON. Proceed with
the approved variant.

**If `feedback-pending.json` found:** The user clicked Regenerate/Remix on the board.
1. Read `regenerateAction` from the JSON (`"different"`, `"match"`, `"more_like_B"`,
   `"remix"`, or custom text)
2. If `regenerateAction` is `"remix"`, read `remixSpec` (e.g. `{"layout":"A","colors":"B"}`)
3. Generate new variants with `$D iterate` or `$D variants` using updated brief
4. Create new board: `$D compare --images "..." --output "$_DESIGN_DIR/design-board.html"`
5. Reload the board in the user's browser (same tab) — the URL is per-board
   under daemon mode, so use `<BOARD_URL>` (from the `BOARD_URL:` stderr
   line) as the base:
   `curl -s -X POST "${BOARD_URL}api/reload" -H 'Content-Type: application/json' -d '{"html":"$_DESIGN_DIR/design-board.html"}'`
   Under `--no-daemon` the reload endpoint is `/api/reload` at the legacy
   port; this path only matters if the caller explicitly opted out of the
   daemon.
6. The board auto-refreshes. **AskUserQuestion again** with the same board URL to
   wait for the next round of feedback. Repeat until `feedback.json` appears.

**If `NO_FEEDBACK_FILE`:** The user typed their preferences directly in the
AskUserQuestion response instead of using the board. Use their text response
as the feedback.

**POLLING FALLBACK:** Only use polling if `$D serve` fails (no port available).
In that case, show each variant inline using the Read tool (so the user can see them),
then use AskUserQuestion:
"The comparison board server failed to start. I've shown the variants above.
Which do you prefer? Any feedback?"

**After receiving feedback (any path):** Output a clear summary confirming
what was understood:

"Here's what I understood from your feedback:
PREFERRED: Variant [X]
RATINGS: [list]
YOUR NOTES: [comments]
DIRECTION: [overall]

Is this right?"

Use AskUserQuestion to verify before proceeding.

**Save the approved choice:**
```bash
echo '{"approved_variant":"<V>","feedback":"<FB>","date":"'$(date -u +%Y-%m-%dT%H:%M:%SZ)'","screen":"<SCREEN>","branch":"'$(git branch --show-current 2>/dev/null)'"}' > "$_DESIGN_DIR/approved.json"
```

**Do NOT use AskUserQuestion to ask which variant the user picked.** Read `feedback.json` — it already contains their preferred variant, ratings, comments, and overall feedback. Only use AskUserQuestion to confirm you understood the feedback correctly, never to re-ask what they chose.

Note which direction was approved. This becomes the visual reference for all subsequent review passes.

**Multiple variants/screens:** If the user asked for multiple variants (e.g., "5 versions of the homepage"), generate ALL as separate variant sets with their own comparison boards. Each screen/variant set gets its own subdirectory under `designs/`. Complete all mockup generation and user selection before starting review passes.

**If `DESIGN_NOT_AVAILABLE`:** Tell the user: "The designer isn't set up yet. Run `$D setup` to enable visual mockups. Proceeding with text-only review, but you're missing the best part." Then proceed to review passes with text-based review.

## Design Outside Voices (parallel)

Use AskUserQuestion:
> "Want outside design voices before the detailed review? Codex evaluates against OpenAI's design hard rules + litmus checks; Claude subagent does an independent completeness review."
>
> A) Yes — run outside design voices
> B) No — proceed without

If user chooses B, skip this step and continue.

**Check Codex availability:**
```bash
command -v codex >/dev/null 2>&1 && echo "CODEX_AVAILABLE" || echo "CODEX_NOT_AVAILABLE"
```

**If Codex is available**, launch both voices simultaneously:

1. **Codex design voice** (via Bash):
```bash
TMPERR_DESIGN=$(mktemp /tmp/codex-design-XXXXXXXX)
_REPO_ROOT=$(git rev-parse --show-toplevel) || { echo "ERROR: not in a git repo" >&2; exit 1; }
codex exec "Read the plan file at [plan-file-path]. Evaluate this plan's UI/UX design against these criteria.

HARD REJECTION — flag if ANY apply:
1. Generic SaaS card grid as first impression
2. Beautiful image with weak brand
3. Strong headline with no clear action
4. Busy imagery behind text
5. Sections repeating same mood statement
6. Carousel with no narrative purpose
7. App UI made of stacked cards instead of layout

LITMUS CHECKS — answer YES or NO for each:
1. Brand/product unmistakable in first screen?
2. One strong visual anchor present?
3. Page understandable by scanning headlines only?
4. Each section has one job?
5. Are cards actually necessary?
6. Does motion improve hierarchy or atmosphere?
7. Would design feel premium with all decorative shadows removed?

HARD RULES — first classify as MARKETING/LANDING PAGE vs APP UI vs HYBRID, then flag violations of the matching rule set:
- MARKETING: First viewport as one composition, brand-first hierarchy, full-bleed hero, 2-3 intentional motions, composition-first layout
- APP UI: Calm surface hierarchy, dense but readable, utility language, minimal chrome
- UNIVERSAL: CSS variables for colors, no default font stacks, one job per section, cards earn existence

For each finding: what's wrong, what will happen if it ships unresolved, and the specific fix. Be opinionated. No hedging." -C "$_REPO_ROOT" -s read-only -c 'model_reasoning_effort="high"' -c 'web_search="cached"' < /dev/null 2>"$TMPERR_DESIGN"
```
Use a 5-minute timeout (`timeout: 300000`). After the command completes, read stderr:
```bash
cat "$TMPERR_DESIGN" && rm -f "$TMPERR_DESIGN"
```

2. **Claude design subagent** (via Agent tool):
Dispatch a subagent with this prompt:
"Read the plan file at [plan-file-path]. You are an independent senior product designer reviewing this plan. You have NOT seen any prior review. Evaluate:

1. Information hierarchy: what does the user see first, second, third? Is it right?
2. Missing states: loading, empty, error, success, partial — which are unspecified?
3. User journey: what's the emotional arc? Where does it break?
4. Specificity: does the plan describe SPECIFIC UI ("48px Söhne Bold header, #1a1a1a on white") or generic patterns ("clean modern card-based layout")?
5. What design decisions will haunt the implementer if left ambiguous?

For each finding: what's wrong, severity (critical/high/medium), and the fix."

**Error handling (all non-blocking):**
- **Auth failure:** If stderr contains "auth", "login", "unauthorized", or "API key": "Codex authentication failed. Run `codex login` to authenticate."
- **Timeout:** "Codex timed out after 5 minutes."
- **Empty response:** "Codex returned no response."
- On any Codex error: proceed with Claude subagent output only, tagged `[single-model]`.
- If Claude subagent also fails: "Outside voices unavailable — continuing with primary review."

Present Codex output under a `CODEX SAYS (design critique):` header.
Present subagent output under a `CLAUDE SUBAGENT (design completeness):` header.

**Synthesis — Litmus scorecard:**

```
DESIGN OUTSIDE VOICES — LITMUS SCORECARD:
═══════════════════════════════════════════════════════════════
  Check                                    Claude  Codex  Consensus
  ─────────────────────────────────────── ─────── ─────── ─────────
  1. Brand unmistakable in first screen?   —       —      —
  2. One strong visual anchor?             —       —      —
  3. Scannable by headlines only?          —       —      —
  4. Each section has one job?             —       —      —
  5. Cards actually necessary?             —       —      —
  6. Motion improves hierarchy?            —       —      —
  7. Premium without decorative shadows?   —       —      —
  ─────────────────────────────────────── ─────── ─────── ─────────
  Hard rejections triggered:               —       —      —
═══════════════════════════════════════════════════════════════
```

Fill in each cell from the Codex and subagent outputs. CONFIRMED = both agree. DISAGREE = models differ. NOT SPEC'D = not enough info to evaluate.

**Pass integration (respects existing 7-pass contract):**
- Hard rejections → raised as the FIRST items in Pass 1, tagged `[HARD REJECTION]`
- Litmus DISAGREE items → raised in the relevant pass with both perspectives
- Litmus CONFIRMED failures → pre-loaded as known issues in the relevant pass
- Passes can skip discovery and go straight to fixing for pre-identified issues

**Log the result:**
```bash
 '{"skill":"design-outside-voices","timestamp":"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'","status":"STATUS","source":"SOURCE","commit":"'"$(git rev-parse --short HEAD)"'"}'
```
Replace STATUS with "clean" or "issues_found", SOURCE with "codex+subagent", "codex-only", "subagent-only", or "unavailable".

## The 0-10 Rating Method

For each design section, rate the plan 0-10 on that dimension. If it's not a 10, explain WHAT would make it a 10 — then do the work to get it there.

Pattern:
1. Rate: "Information Architecture: 4/10"
2. Gap: "It's a 4 because the plan doesn't define content hierarchy. A 10 would have clear primary/secondary/tertiary for every screen."
3. Fix: Edit the plan to add what's missing
4. Re-rate: "Now 8/10 — still missing mobile nav hierarchy"
5. AskUserQuestion if there's a genuine design choice to resolve
6. Fix again → repeat until 10 or user says "good enough, move on"

Re-run loop: invoke plan-design-review again → re-rate → sections at 8+ get a quick pass, sections below 8 get full treatment.

### "Show me what 10/10 looks like" (requires design binary)

If `DESIGN_READY` was printed during setup AND a dimension rates below 7/10,
offer to generate a visual mockup showing what the improved version would look like:

```bash
$D generate --brief "<description of what 10/10 looks like for this dimension>" --output /tmp/ideal-<dimension>.png
```

Show the mockup to the user via the Read tool. This makes the gap between
"what the plan describes" and "what it should look like" visceral, not abstract.

If the design binary is not available, skip this and continue with text-based
descriptions of what 10/10 looks like.

> in full. Do not work from memory — that section is the source of truth for this step.

## Section self-check (before you finish)

Confirm you Read the review section the Section index named, and executed all 7 design passes, the required outputs, and the review report in full. If you produced findings or the review report from memory without Reading `sectionsreview-sections.md`, stop and Read it now.

## EXIT PLAN MODE GATE (BLOCKING)

Before calling ExitPlanMode, run this self-check. If any item fails, do the
missing work — do NOT call ExitPlanMode:

1. Read the plan file with the Read tool (after your most recent write to it).
2. Confirm the LAST `## ` heading in the file is `## GSTACK REVIEW REPORT`.
   In-body prose that mentions "outside voice", "codex findings", or similar
   does NOT count — only the structured `## GSTACK REVIEW REPORT` section
   satisfies this check.
3. Confirm the report has a Runs / Status / Findings table and a VERDICT line
   (CODEX / CROSS-MODEL absorbed if applicable).
4. Confirm the report's FINAL non-whitespace line is the unresolved-decisions
   status: the exact unbolded `NO UNRESOLVED DECISIONS`, or a bullet of a final
   `**UNRESOLVED DECISIONS:**` block. BLOCKING, no "if applicable" escape — a
   bolded sentinel, any trailing CODEX/CROSS-MODEL/VERDICT/prose, or a missing
   status each FAILS the gate.
5. If a plan file is in context for this skill invocation: confirm
   `review-log` was called and `review-read` was run at least
   once. If no plan file is in context (e.g. `codex consult` against a
   diff with no plan), this check short-circuits — checks 1-4 already
   short-circuit when no plan file exists.

Failing this gate and calling ExitPlanMode anyway is a contract violation —
the user will see a plan whose review report is missing or stale, and will
(correctly) reject it. Self-deception failure mode to watch for: feeling
"done" after writing review prose into the plan body. The body prose is not
the report. The report is a separate, structured, table-bearing section that
must be the file's terminal heading.
