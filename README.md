# tstack — AI Engineering Workflow

tstack is a collection of SKILL.md files that give AI agents structured roles for
software development. Each skill is a specialist: CEO reviewer, eng manager,
designer, QA lead, release engineer, debugger, and more.

## Install

### Claude Code

```text
/plugin marketplace add https://github.com/TheophilusChinomona/tstack
/plugin install tstack@tstack
```

Or manually:

```bash
git clone https://github.com/TheophilusChinomona/tstack.git
cd tstack
mkdir -p ~/.claude/skills/tstack
cp -R skills/* ~/.claude/skills/tstack/
```

### Other Harnesses

```bash
# Codex
git clone https://github.com/TheophilusChinomona/tstack.git
cd tstack
cp -R .codex/* ~/.codex/

# Cursor
git clone https://github.com/TheophilusChinomona/tstack.git
cd tstack
cp -R .cursor/* .cursor/

# Hermes
git clone https://github.com/TheophilusChinomona/tstack.git
cd tstack
cp -R .hermes/* ~/.hermes/

# OpenCode
git clone https://github.com/TheophilusChinomona/tstack.git
cd tstack
cp -R .opencode/* .opencode/
```

## Available skills

Skills live in `skills/` (or `~/.claude/skills/tstack/` on install).
Invoke them by name (e.g., `/office-hours`).

### Plan-mode reviews

| Skill | What it does |
|-------|-------------|
| `/office-hours` | Start here. Reframes your product idea before you write code. |
| `/plan-ceo-review` | CEO-level review: find the 10-star product in the request. |
| `/plan-eng-review` | Lock architecture, data flow, edge cases, and tests. |
| `/plan-design-review` | Rate each design dimension 0-10, explain what a 10 looks like. |
| `/plan-devex-review` | DX-mode review: TTHW, magical moments, friction points. |
| `/autoplan` | One command runs CEO → design → eng → DX review. |
| `/design-consultation` | Build a complete design system from scratch. |
| `/spec` | Turn vague intent into a precise, executable spec. |

### Implementation + review

| Skill | What it does |
|-------|-------------|
| `/review` | Pre-landing PR review. Finds bugs that pass CI but break in prod. |
| `/codex` | Second opinion via OpenAI Codex. Review, challenge, or consult modes. |
| `/investigate` | Systematic root-cause debugging. No fixes without investigation. |
| `/design-review` | Live-site visual audit + fix loop with atomic commits. |
| `/design-shotgun` | Generate multiple AI design variants, comparison board, iterate. |
| `/design-html` | Generate production-quality HTML/CSS. |
| `/devex-review` | Live developer experience audit (TTHW measured against the real flow). |
| `/qa` | Open a real browser, find bugs, fix them, re-verify. |
| `/qa-only` | Same methodology as /qa but report only — no code changes. |
| `/scrape` | Pull data from a web page. |
| `/skillify` | Codify the most recent successful scrape flow into a permanent browser-skill. |

### Release + deploy

| Skill | What it does |
|-------|-------------|
| `/ship` | Run tests, review, push, open PR. |
| `/land-and-deploy` | Merge PR, wait for CI/deploy, verify production health. |
| `/canary` | Post-deploy monitoring loop using the browse daemon. |
| `/document-release` | Update all docs to match what you shipped. |
| `/document-generate` | Generate Diataxis docs (tutorial / how-to / reference / explanation) from code. |
| `/setup-deploy` | One-time deploy config detection. |
| `/tstack-upgrade` | Update tstack to the latest version. |

### Operational + memory

| Skill | What it does |
|-------|-------------|
| `/context-save` | Save working context (git state, decisions, remaining work). |
| `/context-restore` | Resume from a saved context. |
| `/learn` | Manage what tstack learned across sessions. |
| `/health` | Code quality dashboard (type checker, linter, tests, dead code). |
| `/benchmark` | Performance regression detection (page load, Core Web Vitals). |
| `/cso` | OWASP Top 10 + STRIDE security audit. |
| `/diagram` | English in, diagram out: mermaid + excalidraw + SVG/PNG, offline. |

### Browser + agent integration

| Skill | What it does |
|-------|-------------|
| `/browse` | Headless browser — real Chromium, real clicks, ~100ms/command. |
| `/open-browser` | Launch visible browser with sidebar + stealth. |
| `/setup-browser-cookies` | Import cookies from your real browser for authenticated testing. |
| `/pair-agent` | Pair a remote AI agent with your browser. |

### Safety + scoping

| Skill | What it does |
|-------|-------------|
| `/careful` | Warn before destructive commands (rm -rf, DROP TABLE, force-push). |
| `/freeze` | Lock edits to one directory. Hard block, not just a warning. |
| `/guard` | Activate both careful + freeze at once. |
| `/unfreeze` | Remove directory edit restrictions. |
| `/make-pdf` | Turn any markdown file into a publication-quality PDF. |

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
- Run `bun run gen:skill-docs --host codex` to regenerate Codex-specific output.
- The browse binary provides headless browser access. Use `$B <command>` in skills.
- Safety skills (careful, freeze, guard) use inline advisory prose — always confirm before destructive operations.
- State paths resolve via `bin/tstack-paths` (sourced via `eval "$(...)"`). Honors `TSTACK_HOME`.
- Skills live in `skills/` — invoke by name (e.g., `/office-hours`).

## Platform support

| Harness | Install | Notes |
|---------|---------|-------|
| Claude Code | `/plugin install tstack@tstack` | Full feature parity |
| Codex | `cp -R .codex/* ~/.codex/` | AGENTS.md-based |
| Cursor | `cp -R .cursor/* .cursor/` | Project rules |
| Hermes | `cp -R .hermes/* ~/.hermes/` | Plugin instructions |
| OpenCode | `cp -R .opencode/* .opencode/` | Plugin manifest |
| GitHub Copilot | `.github/copilot-instructions.md` | Native instruction file |

## Contributing

1. Fork the repo
2. Create your skill in `skills/your-skill-name/SKILL.md` (with YAML frontmatter)
3. Submit a PR with a clear description of what it does and when to use it

## License

MIT. Use it freely, adapt it to your workflow, and contribute back when you can.
