---
name: document-release
preamble-tier: 2
version: 1.0.0
description: Post-ship documentation update. (tstack)
allowed-tools:
  - Bash
  - Read
  - Write
  - Edit
  - Grep
  - Glob
  - AskUserQuestion
triggers:
  - update docs after ship
  - document what changed
  - post-ship docs
---

| When | Read this section |
|------|-------------------|
| auditing each doc file and applying updates, polishing CHANGELOG voice, checking cross-doc consistency, cleaning up TODOS, the VERSION bump, and committing (Steps 2-9, after the coverage map in Step 1.5) | `sections/release-body.md` |

---

## Step 1: Pre-flight & Diff Analysis

1. Check the current branch. If on the base branch, **abort**: "You're on the base branch. Run from a feature branch."

2. Gather context about what changed:

```bash
git diff <base>...HEAD --stat
```

```bash
git log <base>..HEAD --oneline
```

```bash
git diff <base>...HEAD --name-only
```

3. Discover all documentation files in the repo:

```bash
find . -maxdepth 2 -name "*.md" -not -path "./.git/*" -not -path "./node_modules/*" -not -path "././docs/*" -not -path "./.context/*" | sort
```

4. Classify the changes into categories relevant to documentation:
   - **New features** — new files, new commands, new skills, new capabilities
   - **Changed behavior** — modified services, updated APIs, config changes
   - **Removed functionality** — deleted files, removed commands
   - **Infrastructure** — build system, test infrastructure, CI

5. Output a brief summary: "Analyzing N files changed across M commits. Found K documentation files to review."

---

## Step 1.5: Coverage Map (Blast-Radius Analysis)

Before touching any documentation file, build a **coverage map** of what shipped vs what's
documented. This is inspired by the Diataxis framework (tutorial / how-to / reference / explanation)
— but applied as an audit lens, not a generation tool.

1. **Extract public surface changes from the diff.** Scan `git diff <base>...HEAD` for:
   - New exported functions, classes, commands, CLI flags, config options, API endpoints
   - New skills, workflows, or user-facing capabilities
   - Renamed or removed public surface (modules, commands, features)
   - New environment variables, feature flags, or configuration knobs

2. **For each new/changed public surface item, assess documentation coverage:**

```
Coverage map:
  [entity]         [reference?] [how-to?] [tutorial?] [explanation?]
  /new-skill       ✅ AGENTS.md  ❌        ❌          ❌
  --new-flag       ✅ README     ✅ README  ❌          ❌
  FooProcessor     ❌            ❌        ❌          ❌
```

Use these definitions:
- **Reference** — factual description of what it is, its API, its options (README tables, AGENTS.md skill lists, API docs)
- **How-to** — task-oriented: "how to do X with this" (README examples, CONTRIBUTING workflows)
- **Tutorial** — learning-oriented: step-by-step walkthrough for newcomers (getting started guides)
- **Explanation** — understanding-oriented: "why this works this way" (ARCHITECTURE decisions, design rationale)

3. **Output the coverage map.** Items with zero coverage are **critical gaps** — flag them for
   Step 3. Items with reference-only coverage are **common gaps** — note them for the PR body.

4. **Architecture diagram drift detection.** If ARCHITECTURE.md (or any doc) contains ASCII
   diagrams or Mermaid blocks, extract entity names (modules, services, data flows) from the
   diagrams. Cross-reference against the diff. Flag any diagram entities that were renamed,
   split, removed, or moved in the code.

The coverage map feeds into Steps 2-3 (what to audit and fix) and Step 9 (documentation debt
summary in the PR body). Do NOT auto-generate missing documentation pages — flag gaps only.
When significant gaps are found, suggest running `document-generate` to fill them.

---

> in full. Do not work from memory — that section is the source of truth for this step.

---

## Important Rules

- **Read before editing.** Always read the full content of a file before modifying it.
- **Never clobber CHANGELOG.** Polish wording only. Never delete, replace, or regenerate entries.
- **Never bump VERSION silently.** Always ask. Even if already bumped, check whether it covers the full scope of changes.
- **Be explicit about what changed.** Every edit gets a one-line summary.
- **Generic heuristics, not project-specific.** The audit checks work on any repo.
- **Discoverability matters.** Every doc file should be reachable from README or CLAUDE.md.
- **Coverage map informs, never generates.** The Diataxis coverage map flags gaps for the PR body
  and future work. It does NOT auto-generate missing documentation pages or sections. When gaps
  are found, suggest `document-generate` as the follow-up skill.
- **Diagram drift is advisory.** Flag stale architecture diagrams in the PR body but do not
  auto-edit ASCII art or Mermaid blocks — they require human judgment to update correctly.
- **Voice: friendly, user-forward, not obscure.** Write like you're explaining to a smart person
  who hasn't seen the code.
