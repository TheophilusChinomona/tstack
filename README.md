# gstack

> AI engineering workflow — slash commands for Claude Code, Codex, Cursor, and other agents.

**gstack** gives your coding agent structured roles: product reviewer, architect, designer, QA lead, security officer, release engineer. Think → Plan → Build → Review → Test → Ship → Reflect.

This fork is maintained by [Theophilus Chinomona](https://github.com/TheophilusChinomona). It includes security remediation (immutable CI dependencies, trust boundary hardening, dependency overrides) and a scheduled upstream-audit workflow that tests every incoming change before merge.

## Install

```bash
git clone --single-branch --depth 1 https://github.com/TheophilusChinomona/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup
```

Then add to your project's `CLAUDE.md`:

```markdown
## gstack
Use /browse from gstack for all web browsing.
Available skills: /office-hours, /plan-ceo-review, /plan-eng-review, /plan-design-review,
/design-consultation, /design-shotgun, /design-html, /review, /ship, /land-and-deploy,
/canary, /benchmark, /browse, /qa, /qa-only, /design-review, /setup-browser-cookies,
/setup-deploy, /retro, /investigate, /document-release, /document-generate, /codex, /cso,
/autoplan, /careful, /freeze, /guard, /unfreeze, /learn.
```

## Security posture

| Control | What it does |
|---------|-------------|
| Trust boundary hardening | Frontmatter `trusted` is descriptive metadata only — cannot self-elevate to credential-bearing child process |
| Dependency overrides | `protobufjs@7.6.6`, `sharp@0.35.4`, `ip-address@10.5.0` — high-severity advisory chain removed |
| Immutable CI | All GitHub Actions pinned to 40-char commit SHAs — regression test rejects mutable tags |
| Scheduled audit | Daily cron pulls upstream, merges into temp branch, runs tests + build + audit, reports PASS/WARN/BLOCK before any merge |

## Skills

| Category | Skills |
|----------|--------|
| Think | `/office-hours`, `/plan-ceo-review`, `/plan-eng-review`, `/plan-design-review` |
| Build | `/autoplan`, `/design-shotgun`, `/design-html` |
| Review | `/review`, `/codex`, `/investigate` |
| Test | `/qa`, `/qa-only`, `/benchmark` |
| Ship | `/ship`, `/land-and-deploy`, `/canary` |
| Security | `/cso`, `/careful`, `/freeze`, `/guard` |
| Ops | `/retro`, `/learn`, `/document-release` |

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (or compatible agent)
- [Git](https://git-scm.com/)
- [Bun](https://bun.sh/) v1.0+
- [Node.js](https://nodejs.org/) (Windows only)

## License

MIT. Fork it. Improve it. Make it yours.

---

Upstream: [garrytan/gstack](https://github.com/garrytan/gstack) — upstream changes are audited before merge. See `scripts/upstream-audit.sh` for the audit flow.
