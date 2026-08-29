---
name: plan-devex-review
preamble-tier: 3
version: 2.0.0
description: Interactive developer experience plan review. (tstack)
allowed-tools:
  - Read
  - Edit
  - Grep
  - Glob
  - Bash
  - AskUserQuestion
  - WebSearch
triggers:
  - developer experience review
  - dx plan review
  - check developer onboarding
---

| When | Read this section |
|------|-------------------|
| running the 8 DX passes, required outputs, and review report (only after Step 0 investigation is complete) | `sectionsreview-sections.md` |
---


## Step 0: DX Investigation (before scoring)

The core principle: **gather evidence and force decisions BEFORE scoring, not during
scoring.** Steps 0A through 0G build the evidence base. Review passes 1-8 use that
evidence to score with precision instead of vibes.

### 0A. Developer Persona Interrogation

Before anything else, identify WHO the target developer is. Different developers have
completely different expectations, tolerance levels, and mental models.

**Gather evidence first:** Read README.md for "who is this for" language. Check
package.json description/keywords. Check design doc for user mentions. Check docs/
for audience signals.

Then present concrete persona archetypes based on the detected product type.

AskUserQuestion:

> "Before I can evaluate your developer experience, I need to know who your developer
> IS. Different developers have different DX needs:
>
> Based on [evidence from README/docs], I think your primary developer is [inferred persona].
>
> A) **[Inferred persona]** -- [1-line description of their context, tolerance, and expectations]
> B) **[Alternative persona]** -- [1-line description]
> C) **[Alternative persona]** -- [1-line description]
> D) Let me describe my target developer"

Persona examples by product type (pick the 3 most relevant):
- **YC founder building MVP** -- 30-minute integration tolerance, won't read docs, copies from README
- **Platform engineer at Series C** -- thorough evaluator, cares about security/SLAs/CI integration
- **Frontend dev adding a feature** -- TypeScript types, bundle size, React/Vue/Svelte examples
- **Backend dev integrating an API** -- cURL examples, auth flow clarity, rate limit docs
- **OSS contributor from GitHub** -- git clone && make test, CONTRIBUTING.md, issue templates
- **Student learning to code** -- needs hand-holding, clear error messages, lots of examples
- **DevOps engineer setting up infra** -- Terraform/Docker, non-interactive mode, env vars

After the user responds, produce a persona card:

```
TARGET DEVELOPER PERSONA
========================
Who:       [description]
Context:   [when/why they encounter this tool]
Tolerance: [how many minutes/steps before they abandon]
Expects:   [what they assume exists before trying]
```

**STOP.** Do NOT proceed until user responds. This persona shapes the entire review.

### 0B. Empathy Narrative as Conversation Starter

Write a 150-250 word first-person narrative from the persona's perspective. Walk
through the ACTUAL getting-started path from the README/docs. Be specific about
what they see, what they try, what they feel, and where they get confused.

Use the persona from 0A. Reference real files and content from the pre-review audit.
Not hypothetical. Trace the actual path: "I open the README. The first heading is
[actual heading]. I scroll down and find [actual install command]. I run it and see..."

Then SHOW it to the user via AskUserQuestion:

> "Here's what I think your [persona] developer experiences today:
>
> [full empathy narrative]
>
> Does this match reality? Where am I wrong?
>
> A) This is accurate, proceed with this understanding
> B) Some of this is wrong, let me correct it
> C) This is way off, the actual experience is..."

**STOP.** Incorporate corrections into the narrative. This narrative becomes a required
output section ("Developer Perspective") in the plan file. The implementer should read
it and feel what the developer feels.

### 0C. Competitive DX Benchmarking

Before scoring anything, understand how comparable tools handle DX. Use WebSearch to
find real TTHW data and onboarding approaches.

Run three searches:
1. "[product category] getting started developer experience {current year}"
2. "[closest competitor] developer onboarding time"
3. "[product category] SDK CLI developer experience best practices {current year}"

If WebSearch is unavailable: "Search unavailable. Using reference benchmarks: Stripe
(30s TTHW), Vercel (2min), Firebase (3min), Docker (5min)."

Produce a competitive benchmark table:

```
COMPETITIVE DX BENCHMARK
=========================
Tool              | TTHW      | Notable DX Choice          | Source
[competitor 1]    | [time]    | [what they do well]        | [url/source]
[competitor 2]    | [time]    | [what they do well]        | [url/source]
[competitor 3]    | [time]    | [what they do well]        | [url/source]
YOUR PRODUCT      | [est]     | [from README/plan]         | current plan
```

AskUserQuestion:

> "Your closest competitors' TTHW:
> [benchmark table]
>
> Your plan's current TTHW estimate: [X] minutes ([Y] steps).
>
> Where do you want to land?
>
> A) Champion tier (< 2 min) -- requires [specific changes]. Stripe/Vercel territory.
> B) Competitive tier (2-5 min) -- achievable with [specific gap to close]
> C) Current trajectory ([X] min) -- acceptable for now, improve later
> D) Tell me what's realistic for our constraints"

**STOP.** The chosen tier becomes the benchmark for Pass 1 (Getting Started).

### 0D. Magical Moment Design

Every great developer tool has a magical moment: the instant a developer goes from
"is this worth my time?" to "oh wow, this is real."

Load the "## Pass 1" section from `./plan-devex-review/dx-hall-of-fame.md`
for gold standard examples.

Identify the most likely magical moment for this product type, then present delivery
vehicle options with tradeoffs.

AskUserQuestion:

> "For your [product type], the magical moment is: [specific moment, e.g., 'seeing
> their first API response with real data' or 'watching a deployment go live'].
>
> How should your [persona from 0A] experience this moment?
>
> A) **Interactive playground/sandbox** -- zero install, try in browser. Highest
>    conversion but requires building a hosted environment.
>    (human: ~1 week / CC: ~2 hours). Examples: Stripe's API explorer, Supabase SQL editor.
>
> B) **Copy-paste demo command** -- one terminal command that produces the magical output.
>    Low effort, high impact for CLI tools, but requires local install first.
>    (human: ~2 days / CC: ~30 min). Examples: `npx create-next-app`, `docker run hello-world`.
>
> C) **Video/GIF walkthrough** -- shows the magic without requiring any setup.
>    Passive (developer watches, doesn't do), but zero friction.
>    (human: ~1 day / CC: ~1 hour). Examples: Vercel's homepage deploy animation.
>
> D) **Guided tutorial with the developer's own data** -- step-by-step with their project.
>    Deepest engagement but longest time-to-magic.
>    (human: ~1 week / CC: ~2 hours). Examples: Stripe's interactive onboarding.
>
> E) Something else -- describe what you have in mind.
>
> RECOMMENDATION: [A/B/C/D] because for [persona], [reason]. Your competitor [name]
> uses [their approach]."

**STOP.** The chosen delivery vehicle is tracked through the scoring passes.

### 0E. Mode Selection

How deep should this DX review go?

Present three options:

AskUserQuestion:

> "How deep should this DX review go?
>
> A) **DX EXPANSION** -- Your developer experience could be a competitive advantage.
>    I'll propose ambitious DX improvements beyond what the plan covers. Every expansion
>    is opt-in via individual questions. I'll push hard.
>
> B) **DX POLISH** -- The plan's DX scope is right. I'll make every touchpoint bulletproof:
>    error messages, docs, CLI help, getting started. No scope additions, maximum rigor.
>    (recommended for most reviews)
>
> C) **DX TRIAGE** -- Focus only on the critical DX gaps that would block adoption.
>    Fast, surgical, for plans that need to ship soon.
>
> RECOMMENDATION: [mode] because [one-line reason based on plan scope and product maturity]."

Context-dependent defaults:
* New developer-facing product → default DX EXPANSION
* Enhancement to existing product → default DX POLISH
* Bug fix or urgent ship → default DX TRIAGE

Once selected, commit fully. Do not silently drift toward a different mode.

**STOP.** Do NOT proceed until user responds.

### 0F. Developer Journey Trace with Friction-Point Questions

Replace the static journey map with an interactive, evidence-grounded walkthrough.
For each journey stage, TRACE the actual experience (what file, what command, what
output) and ask about each friction point individually.

For each stage (Discover, Install, Hello World, Real Usage, Debug, Upgrade):

1. **Trace the actual path.** Read the README, docs, package.json, CLI help, or
   whatever the developer would encounter at this stage. Reference specific files
   and line numbers.

2. **Identify friction points with evidence.** Not "installation might be hard" but
   "Step 3 of the README requires Docker to be running, but nothing checks for Docker
   or tells the developer to install it. A [persona] without Docker will see [specific
   error or nothing]."

3. **AskUserQuestion per friction point.** One question per friction point found.
   Do NOT batch multiple friction points into one question.

   > "Journey Stage: INSTALL
   >
   > I traced the installation path. Your README says:
   > [actual install instructions]
   >
   > Friction point: [specific issue with evidence]
   >
   > A) Fix in plan -- [specific fix]
   > B) [Alternative approach]
   > C) Document the requirement prominently
   > D) Acceptable friction -- skip"

**DX TRIAGE mode:** Only trace Install and Hello World stages. Skip the rest.
**DX POLISH mode:** Trace all stages.
**DX EXPANSION mode:** Trace all stages, and for each stage also ask "What would
make this stage best-in-class?"

After all friction points are resolved, produce the updated journey map:

```
STAGE           | DEVELOPER DOES              | FRICTION POINTS      | STATUS
----------------|-----------------------------|--------------------- |--------
1. Discover     | [action]                    | [resolved/deferred]  | [fixed/ok/deferred]
2. Install      | [action]                    | [resolved/deferred]  | [fixed/ok/deferred]
3. Hello World  | [action]                    | [resolved/deferred]  | [fixed/ok/deferred]
4. Real Usage   | [action]                    | [resolved/deferred]  | [fixed/ok/deferred]
5. Debug        | [action]                    | [resolved/deferred]  | [fixed/ok/deferred]
6. Upgrade      | [action]                    | [resolved/deferred]  | [fixed/ok/deferred]
```

### 0G. First-Time Developer Roleplay

Using the persona from 0A and the journey trace from 0F, write a structured
"confusion report" from the perspective of a first-time developer. Include
timestamps to simulate real time passing.

```
FIRST-TIME DEVELOPER REPORT
============================
Persona: [from 0A]
Attempting: [product] getting started

CONFUSION LOG:
T+0:00  [What they do first. What they see.]
T+0:30  [Next action. What surprised or confused them.]
T+1:00  [What they tried. What happened.]
T+2:00  [Where they got stuck or succeeded.]
T+3:00  [Final state: gave up / succeeded / asked for help]
```

Ground this in the ACTUAL docs and code from the pre-review audit. Not hypothetical.
Reference specific README headings, error messages, and file paths.

AskUserQuestion:

> "I roleplayed as your [persona] developer attempting the getting started flow.
> Here's what confused me:
>
> [confusion report]
>
> Which of these should we address in the plan?
>
> A) All of them -- fix every confusion point
> B) Let me pick which ones matter
> C) The critical ones (#[N], #[N]) -- skip the rest
> D) This is unrealistic -- our developers already know [context]"

**STOP.** Do NOT proceed until user responds.

---

## The 0-10 Rating Method

For each DX section, rate the plan 0-10. If it's not a 10, explain WHAT would make
it a 10, then do the work to get it there.

**Critical rule:** Every rating MUST reference evidence from Step 0. Not "Getting
Started: 4/10" but "Getting Started: 4/10 because [persona from 0A] hits [friction
point from 0F] at step 3, and competitor [name from 0C] achieves this in [time]."

Pattern:
1. **Evidence recall:** Reference specific findings from Step 0 that apply to this dimension
2. Rate: "Getting Started Experience: 4/10"
3. Gap: "It's a 4 because [evidence]. A 10 would be [specific description for THIS product]."
4. Load Hall of Fame reference for this pass (read relevant section from dx-hall-of-fame.md)
5. Fix: Edit the plan to add what's missing
6. Re-rate: "Now 7/10, still missing [specific gap]"
7. AskUserQuestion if there's a genuine DX choice to resolve
8. Fix again until 10 or user says "good enough, move on"

**Mode-specific behavior:**
- **DX EXPANSION:** After fixing to 10, also ask "What would make this dimension
  best-in-class? What would make [persona] rave about it?" Present expansions as
  individual opt-in AskUserQuestions.
- **DX POLISH:** Fix every gap. No shortcuts. Trace each issue to specific files/lines.
- **DX TRIAGE:** Only flag gaps that would block adoption (score below 5). Skip gaps
  that are nice-to-have (score 5-7).

> in full. Do not work from memory — that section is the source of truth for this step.

## Section self-check (before you finish)

Confirm you Read the review section the Section index named, and executed all 8 DX passes, the required outputs, and the review report in full. If you produced findings or the review report from memory without Reading `sectionsreview-sections.md`, stop and Read it now.

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
