---
name: plan-eng-review
preamble-tier: 3
version: 1.0.0
description: Eng manager-mode plan review. (tstack)
allowed-tools:
  - Read
  - Write
  - Grep
  - Glob
  - AskUserQuestion
  - Bash
  - WebSearch
triggers:
  - review architecture
  - eng plan review
  - check the implementation plan
---

| When | Read this section |
|------|-------------------|
| running the 4-section review, outside voice, required outputs, and review report (only after Step 0 scope is agreed) | `sectionsreview-sections.md` |
---


### Design Doc Check
```bash
setopt +o nomatch 2>/dev/null || true  # zsh compat
SLUG=$(./skills/browse/bin/remote-slug 2>/dev/null || basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-' || echo 'no-branch')
_LOCALDOC=$(ls -t ./docs/projects/$SLUG/*-$BRANCH-design-*.md 2>/dev/null | head -1)
[ -z "$_LOCALDOC" ] && _LOCALDOC=$(ls -t ./docs/projects/$SLUG/*-design-*.md 2>/dev/null | head -1)
# Repo-local docs win when at least as fresh (#703): office-hours dual-writes
# docs/designs/ alongside ./docs, and the committed copy is what teammates
# see. A stale old repo doc never shadows a newer private session.
_REPOTOP=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_REPODOC=""
if [ -n "$_REPOTOP" ]; then
  [ -f "$_REPOTOP/DESIGN.md" ] && _REPODOC="$_REPOTOP/DESIGN.md"
  [ -z "$_REPODOC" ] && _REPODOC=$(ls -t "$_REPOTOP"/docs/designs/*.md 2>/dev/null | head -1)
fi
DESIGN="$_LOCALDOC"
if [ -n "$_REPODOC" ] && { [ -z "$_LOCALDOC" ] || [ "$_REPODOC" -nt "$_LOCALDOC" ]; }; then
  DESIGN="$_REPODOC"
fi
[ -n "$DESIGN" ] && echo "Design doc found: $DESIGN" || echo "No design doc found"
```
If a design doc exists, read it. Use it as the source of truth for the problem statement, constraints, and chosen approach. If it has a `Supersedes:` field, note that this is a revised design — check the prior version for context on what changed and why.

## Prerequisite Skill Offer

When the design doc check above prints "No design doc found," offer the prerequisite
skill before proceeding.

Say to the user via AskUserQuestion:

> "No design doc found for this branch. `office-hours` produces a structured problem
> statement, premise challenge, and explored alternatives — it gives this review much
> sharper input to work with. Takes about 10 minutes. The design doc is per-feature,
> not per-product — it captures the thinking behind this specific change."

Options:
- A) Run office-hours now (we'll pick up the review right after)
- B) Skip — proceed with standard review

If they skip: "No worries — standard review. If you ever want sharper input, try
office-hours first next time." Then proceed normally. Do not re-offer later in the session.

If they choose A:

Say: "Running office-hours inline. Once the design doc is ready, I'll pick up
the review right where we left off."

Read the `office-hours` skill file at `./skills/office-hours/SKILL.md` using the Read tool.

**If unreadable:** Skip with "Could not load office-hours — skipping." and continue.

Follow its instructions from top to bottom, **skipping these sections** (already handled by the parent skill):
- Preamble (run first)
- AskUserQuestion Format
- Completeness Principle — Boil the Ocean
- Search Before Building
- Contributor Mode
- Completion Status Protocol
- Telemetry (run last)
- Step 0: Detect platform and base branch
- Review Readiness Dashboard
- Plan File Review Report
- Prerequisite Skill Offer
- Plan Status Footer

Execute every other section at full depth. When the loaded skill's instructions are complete, continue with the next step below.

After office-hours completes, re-run the design doc check:
```bash
setopt +o nomatch 2>/dev/null || true  # zsh compat
SLUG=$(./skills/browse/bin/remote-slug 2>/dev/null || basename "$(git rev-parse --show-toplevel 2>/dev/null || pwd)")
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null | tr '/' '-' || echo 'no-branch')
_LOCALDOC=$(ls -t ./docs/projects/$SLUG/*-$BRANCH-design-*.md 2>/dev/null | head -1)
[ -z "$_LOCALDOC" ] && _LOCALDOC=$(ls -t ./docs/projects/$SLUG/*-design-*.md 2>/dev/null | head -1)
# Repo-local docs win when at least as fresh (#703): office-hours dual-writes
# docs/designs/ alongside ./docs, and the committed copy is what teammates
# see. A stale old repo doc never shadows a newer private session.
_REPOTOP=$(git rev-parse --show-toplevel 2>/dev/null || echo "")
_REPODOC=""
if [ -n "$_REPOTOP" ]; then
  [ -f "$_REPOTOP/DESIGN.md" ] && _REPODOC="$_REPOTOP/DESIGN.md"
  [ -z "$_REPODOC" ] && _REPODOC=$(ls -t "$_REPOTOP"/docs/designs/*.md 2>/dev/null | head -1)
fi
DESIGN="$_LOCALDOC"
if [ -n "$_REPODOC" ] && { [ -z "$_LOCALDOC" ] || [ "$_REPODOC" -nt "$_LOCALDOC" ]; }; then
  DESIGN="$_REPODOC"
fi
[ -n "$DESIGN" ] && echo "Design doc found: $DESIGN" || echo "No design doc found"
```

If a design doc is now found, read it and continue the review.
If none was produced (user may have cancelled), proceed with standard review.

### Step 0: Scope Challenge

> Reminder: the **Scope gate** at the top of this skill applies first. Do not run Step 0 until the gate has resolved a target — the user answered, the user named one, or plan mode auto-selected B — and run it against that target.

Before reviewing anything, answer these questions:
1. **What existing code already partially or fully solves each sub-problem?** Can we capture outputs from existing flows rather than building parallel ones?
2. **What is the minimum set of changes that achieves the stated goal?** Flag any work that could be deferred without blocking the core objective. Be ruthless about scope creep.
3. **Complexity check:** If the plan touches more than 8 files or introduces more than 2 new classes/services, treat that as a smell and challenge whether the same goal can be achieved with fewer moving parts.
4. **Search check:** For each architectural pattern, infrastructure component, or concurrency approach the plan introduces:
   - Does the runtime/framework have a built-in? Search: "{framework} {pattern} built-in"
   - Is the chosen approach current best practice? Search: "{pattern} best practice {current year}"
   - Are there known footguns? Search: "{framework} {pattern} pitfalls"

   If WebSearch is unavailable, skip this check and note: "Search unavailable — proceeding with in-distribution knowledge only."

   If the plan rolls a custom solution where a built-in exists, flag it as a scope reduction opportunity. Annotate recommendations with **[Layer 1]**, **[Layer 2]**, **[Layer 3]**, or **[EUREKA]** (see preamble's Search Before Building section). If you find a eureka moment — a reason the standard approach is wrong for this case — present it as an architectural insight.
5. **TODOS cross-reference:** Read `TODOS.md` if it exists. Are any deferred items blocking this plan? Can any deferred items be bundled into this PR without expanding scope? Does this plan create new work that should be captured as a TODO?

5. **Completeness check:** Is the plan doing the complete version or a shortcut? With AI-assisted coding, the cost of completeness (100% test coverage, full edge case handling, complete error paths) is 10-100x cheaper than with a human team. If the plan proposes a shortcut that saves human-hours but only saves minutes with AI-assisted coding, recommend the complete version. Boil the ocean.

6. **Distribution check:** If the plan introduces a new artifact type (CLI binary, library package, container image, mobile app), does it include the build/publish pipeline? Code without distribution is code nobody can use. Check:
   - Is there a CI/CD workflow for building and publishing the artifact?
   - Are target platforms defined (linux/darwin/windows, amd64/arm64)?
   - How will users download or install it (GitHub Releases, package manager, container registry)?
   If the plan defers distribution, flag it explicitly in the "NOT in scope" section — don't let it silently drop.

If the complexity check triggers (8+ files or 2+ new classes/services), STOP before any review-section work. Call AskUserQuestion: name what's overbuilt, propose a minimal version that achieves the core goal, ask whether to reduce or proceed as-is. The AskUserQuestion call is a tool_use, not prose — call the tool directly.

**STOP.** Do NOT proceed to Section 1 (Architecture review), edit the plan file with a proposed scope reduction, or call ExitPlanMode until the user responds. Naming the 80% solution in chat prose and continuing — or loading the AskUserQuestion schema via ToolSearch and then never invoking it — is the failure mode this gate exists to prevent.

If the complexity check does not trigger, present your Step 0 findings and proceed directly to Section 1.

Always work through the full interactive review: one section at a time (Architecture → Code Quality → Tests → Performance) with at most 8 top issues per section.

**Critical: Once the user accepts or rejects a scope reduction recommendation, commit fully.** Do not re-argue for smaller scope during later review sections. Do not silently reduce scope or skip planned components.

> in full. Do not work from memory — that section is the source of truth for this step.

## Section self-check (before you finish)

Confirm you Read the review section the Section index named, and executed every review section (Architecture, Code Quality, Tests, Performance), the outside voice, and the required outputs in full. If you produced findings or the review report from memory without Reading `sectionsreview-sections.md`, stop and Read it now.

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
