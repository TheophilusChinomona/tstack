# tstack — Codex Instructions

tstack is an AI engineering workflow system. Skills are in `skills/`. Invoke them by name.

## Available Skills

### Plan-mode reviews
- `office-hours` — Reframes product ideas before coding
- `plan-ceo-review` — CEO-level review: find the 10-star product
- `plan-eng-review` — Lock architecture, data flow, edge cases, tests
- `plan-design-review` — Rate design 0-10, explain what 10 looks like
- `plan-devex-review` — DX-mode: TTHW, magical moments, friction
- `autoplan` — Runs CEO → design → eng → DX review
- `design-consultation` — Build complete design system from scratch
- `spec` — Turn vague intent into executable spec

### Implementation + review
- `review` — Pre-landing PR review
- `codex` — Second opinion via OpenAI Codex
- `investigate` — Systematic root-cause debugging
- `design-review` — Live-site visual audit + fix loop
- `design-shotgun` — Multiple AI design variants + comparison
- `design-html` — Production-quality HTML/CSS
- `devex-review` — Live developer experience audit
- `qa` — Open real browser, find bugs, fix, re-verify
- `qa-only` — Report-only QA
- `scrape` — Pull data from web pages
- `skillify` — Codify scrape flow into permanent skill

### Release + deploy
- `ship` — Tests → review → push → PR
- `land-and-deploy` — Merge PR, wait for CI/deploy, verify prod
- `canary` — Post-deploy monitoring loop
- `document-release` — Update docs to match shipped code
- `document-generate` — Generate Diataxis docs from code
- `setup-deploy` — One-time deploy config detection
- `tstack-upgrade` — Update tstack to latest version

### Operational + memory
- `context-save` — Save working context
- `context-restore` — Resume from saved context
- `learn` — Manage project learnings
- `health` — Code quality dashboard
- `benchmark` — Performance regression detection
- `cso` — OWASP Top 10 + STRIDE security audit
- `diagram` — English → mermaid + excalidraw + SVG/PNG

### Browser + agent integration
- `browse` — Headless browser — real Chromium, real clicks
- `open-browser` — Launch visible browser with sidebar
- `setup-browser-cookies` — Import real browser cookies
- `pair-agent` — Pair remote AI agent with your browser

### Safety + scoping
- `careful` — Warn before destructive commands
- `freeze` — Lock edits to one directory
- `guard` — Activate careful + freeze together
- `unfreeze` — Remove directory edit restrictions
- `make-pdf` — Markdown → publication-quality PDF

## Build commands
```bash
bun install              # install dependencies
bun run test             # run tests
bun run build            # generate docs + compile binaries
bun run gen:skill-docs   # regenerate SKILL.md files from templates
bun run skill:check      # health dashboard for all skills
```

## Key conventions
- SKILL.md files are **generated** from `.tmpl` templates. Edit the template, not the output.
- The browse binary provides headless browser access. Use `$B <command>` in skills.
- Safety skills (careful, freeze, guard) use inline advisory prose — always confirm before destructive operations.
- State paths resolve via `bin/tstack-paths`. Honors `TSTACK_HOME`.
