---
name: pair-agent
preamble-tier: 2
version: 0.1.0
description: Pair a remote AI agent with your browser. (tstack)
triggers:
  - pair with agent
  - connect remote agent
  - share my browser
allowed-tools:
  - Bash
  - Read
  - AskUserQuestion

---

## When to invoke this skill

One command generates a setup key and
prints instructions the other agent can follow to connect. Works with OpenClaw,
Hermes, Codex, Cursor, or any agent that can make HTTP requests. The remote agent
gets its own tab with full page access by default (the pairing ceremony is the
trust boundary; --restrict narrows it).
Use when asked to "pair agent", "connect agent", "share browser", "remote browser",
"let another agent use my browser", or "give browser access".

Voice triggers (speech-to-text aliases): "pair agent", "connect agent", "share my browser", "remote browser access".

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

# pair-agent — Share Your Browser With Another AI Agent

You're sitting in Claude Code with a browser running. You also have another AI agent
open (OpenClaw, Hermes, Codex, Cursor, whatever). You want that other agent to be
able to browse the web using YOUR browser. This skill makes that happen.

## How it works

Your gstack browser runs a local HTTP server. This skill creates a one-time setup key,
prints a block of instructions, and you paste those instructions into the other agent.
The other agent exchanges the key for a session token, creates its own tab, and starts
browsing. Each agent gets its own tab. They can't mess with each other's tabs.

The setup key expires in 5 minutes and can only be used once. If it leaks, it's dead
before anyone can abuse it. The session token lasts 24 hours.

**Same machine:** If the other agent is on the same machine (like OpenClaw running
locally), you can skip the copy-paste ceremony and write the credentials directly to
the agent's config directory.

**Remote:** If the other agent is on a different machine, you need an ngrok tunnel.
The skill will tell you if one is needed and how to set it up.

## SETUP (run this check BEFORE any browse command)

```bash
_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
B=""
[ -n "$_ROOT" ] && [ -x "$_ROOT/browse/dist/browse" ] && B="$_ROOT/browse/dist/browse"
[ -z "$B" ] && B="$HOME/.claude/skills/gstackbrowse/distbrowse"
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

## Step 1: Check prerequisites

```bash
$B status 2>/dev/null
```

If the browse server is not running, start it:

```bash
$B goto about:blank
```

This ensures the server is up and healthy before pairing.

## Step 2: Ask what they want

Use AskUserQuestion:

> Which agent do you want to pair with your browser? This determines the
> instructions format and where credentials get written.

Options:
- A) OpenClaw (local or remote)
- B) Codex / OpenAI Agents (local)
- C) Cursor (local)
- D) Another Claude Code session (local or remote)
- E) Something else (generic HTTP instructions — use this for Hermes)

Based on the answer, set `TARGET_HOST`:
- A → `openclaw`
- B → `codex`
- C → `cursor`
- D → `claude`
- E → generic (no host-specific config)

## Step 3: Local or remote?

Use AskUserQuestion:

> Is the other agent running on this same machine, or on a different machine/server?
>
> **Same machine** skips the copy-paste ceremony. Credentials are written directly to
> the agent's config directory. No tunnel needed.
>
> **Different machine** generates a setup key and instruction block. If ngrok is
> installed, the tunnel starts automatically. If not, I'll walk you through setup.
>
> RECOMMENDATION: Choose A if the agent is local. It's instant, no copy-paste needed.

Options:
- A) Same machine (write credentials directly)
- B) Different machine (generate instruction block for copy-paste)

## Step 4: Execute pairing

**Live-daemon consent (one-way door).** Pairing can relaunch the browser
daemon; a relaunch KILLS the running headless daemon — open tabs, cookies,
and logged-in sessions die with it. The CLI honors the iron rule (only an
explicit `--force-restart` may kill a live daemon), so check first:

```bash
$B status 2>/dev/null | head -5
```

If a daemon is running, ask via AskUserQuestion (one-way door — lost
tabs/cookies/logins cannot be recovered):

> "A headless browser daemon is live (tabs and logins may be active). Pairing
> headed requires relaunching it — everything in the current daemon is lost.
>
> RECOMMENDATION: Choose B unless the remote agent specifically needs a
> visible browser window; pairing works against the existing daemon."

Options:
- A) Relaunch (pass `--force-restart`; current tabs/cookies/logins are lost)
- B) Keep the live daemon (recommended — pair against it as-is)

Only pass `--force-restart` to the commands below after an explicit A. Never
default to A on a vague reply — this is a destructive confirmation.

### If same machine (option A):

Run pair-agent with --local flag:

```bash
$B pair-agent --local TARGET_HOST
```

Replace `TARGET_HOST` with the value from Step 2 (openclaw, codex, cursor, etc.).

If it succeeds, tell the user:
"Done. TARGET_HOST can now use your browser. It will read credentials from the
config file that was written. Try asking it to navigate to a URL."

If it fails (host not found, write permission error), show the error and suggest
using the generic remote flow instead.

### If different machine (option B):

**Consent gate (once per machine).** The tunnel exposes this browser beyond
the machine, so it is OFF until the user opts in — the daemon refuses
`/tunnel/start` and `BROWSE_TUNNEL=1` otherwise. Check the standing consent:

```bash
 get pair_agent 2>/dev/null || echo "unset"
```

If the value is not `on`, ask via AskUserQuestion (one-way-door posture —
this opens a path from the internet to the local browser):

> "Remote pairing runs an ngrok tunnel from the internet to this machine's
> browser (locked to a 26-command allowlist + scoped token, but still an
> exposure). Enable pair-agent on this machine?"

Options: A) Enable — run ` set pair_agent on`, confirm it reads back `on`, and continue. B) No — stop here; local pairing (option A above) still works.

If the value is already `on`, say nothing and continue — consent stands until
`config set pair_agent off`.

Then detect ngrok status:

```bash
which ngrok 2>/dev/null && echo "NGROK_INSTALLED" || echo "NGROK_NOT_INSTALLED"
ngrok config check 2>/dev/null && echo "NGROK_AUTHED" || echo "NGROK_NOT_AUTHED"
```

**If ngrok is installed and authed:** Just run the command. The CLI will auto-detect
ngrok, start the tunnel, and print the instruction block with the tunnel URL:

```bash
$B pair-agent --client TARGET_HOST
```

Default access already includes JS execution. To also grant browser-wide
control (stop, restart, disconnect):

```bash
$B pair-agent --control --client TARGET_HOST
```

For a less-trusted agent, narrow the scopes instead:

```bash
$B pair-agent --restrict read --client TARGET_HOST            # read-only
$B pair-agent --restrict "read,write" --client TARGET_HOST    # no JS, no cookies
```

**CRITICAL: You MUST output the full instruction block to the user.** The command
prints everything between ═══ lines. Copy the ENTIRE block verbatim into your
response so the user can copy-paste it into their other agent. Do NOT summarize it,
do NOT skip it, do NOT just say "here's the output." The user needs to SEE the block
to copy it. Output it inside a markdown code block so it's easy to select and copy.

Then tell the user:
"Copy the block above and paste it into your other agent's chat. The setup key
expires in 5 minutes."

**If ngrok is installed but NOT authed:** Walk the user through authentication.

SECURITY: the ngrok authtoken must NEVER pass through this chat, a Bash tool
call, or shell history — a token pasted here lands in the transcript (and
anything the transcript syncs to). The user runs the auth command in their
OWN terminal; you only verify the result.

Tell the user:
"ngrok is installed but not logged in. Let's fix that — in your own terminal
(not here; the token should never enter this chat):

1. Go to https://dashboard.ngrok.com/get-started/your-authtoken
2. Copy your auth token
3. In YOUR terminal, run: ngrok config add-authtoken <paste your token>
4. Tell me 'done' when finished."

STOP here and wait for the user to say they've run it. Do NOT accept a pasted
token; if the user pastes one anyway, tell them to rotate it at
https://dashboard.ngrok.com (it's now in the transcript) and re-auth in their
terminal with the new one.

When they say done, verify without touching the token:
```bash
ngrok config check 2>/dev/null && echo "NGROK_AUTHED" || echo "NGROK_NOT_AUTHED"
```

If `NGROK_AUTHED`: retry `$B pair-agent --client TARGET_HOST`.
If still `NGROK_NOT_AUTHED`: ask them to re-run the command in their terminal.

**If ngrok is NOT installed:** Walk the user through installation:

Tell the user:
"To connect a remote agent, we need ngrok (a tunnel that exposes your local
browser to the internet securely).

1. Go to https://ngrok.com and sign up (free tier works)
2. Install ngrok:
   - macOS: `brew install ngrok`
   - Linux: `snap install ngrok` or download from ngrok.com/download
3. Auth it: `ngrok config add-authtoken YOUR_TOKEN`
   (get your token from https://dashboard.ngrok.com/get-started/your-authtoken)
4. Come back here and run `pair-agent` again."

STOP here. Wait for the user to install ngrok and re-invoke.

## Step 5: Verify connection

After the user pastes the instructions into the other agent, wait a moment then check:

```bash
$B status
```

Look for the connected agent in the status output. If it appears, tell the user:
"The remote agent is connected and has its own tab. You'll see its activity in the
side panel if you have the browser open."

## What the remote agent can do

Default access is read+write+admin+meta. The trust boundary is the pairing
ceremony, not the scope:
- Navigate to URLs, click elements, fill forms, take screenshots
- Read page content (text, HTML, snapshot)
- Create new tabs (each agent gets its own)
- Execute JavaScript via `eval`
- Cannot stop or restart the browser, or disconnect headed mode (needs --control)

Remote agents go through the tunnel command allowlist: `eval` works, but the
`js`, `cookies`, and `storage` commands are not dispatchable over the tunnel
even with admin scope. Agents paired with `--local` get all four.

With --restrict (`--restrict read`, `--restrict "read,write"`):
- Sandboxed sessions: read-only, or read+write with no JS, cookie, or storage
  access. Pair this way when the remote agent will read untrusted web content:
  a trusted agent can be prompt-injected by pages it reads, and scope caps the
  blast radius (eval works over the tunnel).
- `--restrict` never grants `control`; that scope stays behind --control.
- To tighten an agent that is ALREADY paired, re-pair it with the **same
  `--client` name** and the narrower `--restrict`/`--domain`. A reducing re-pair
  revokes the previous session immediately and releases its tabs — the agent
  must reconnect with the new key, so the old wide access does not linger.
  Re-pairing without `--client` mints a brand-new agent and leaves the old one
  untouched. Broadening or refreshing keeps the working session (no outage).
- `root` is a reserved `--client` name (it would bypass all scope enforcement).

With --control (--admin is the legacy alias):
- Everything, plus browser-wide destructive ops (stop, restart, disconnect)
- Only for agents you fully trust.

## Troubleshooting

**"Tab not owned by your agent"** — The remote agent tried to interact with a tab
it didn't create. Tell it to run `newtab` first to get its own tab.

**"Domain not allowed"** — The token has domain restrictions. Re-pair with the
same `--client` name and broader (or no) `--domain`. A broadening re-pair keeps
the working session; a narrowing one revokes it immediately.

**"Rate limit exceeded"** — The agent is sending > 10 requests/second. It should
wait for the Retry-After header and slow down.

**"Token expired"** — The 24-hour session expired. Run `pair-agent` again to
generate a new setup key.

**Agent can't reach the server** — If remote, check the ngrok tunnel is running
(`$B status`). If local, check the browse server is running.

### OpenClaw / AlphaClaw

OpenClaw agents use the `exec` tool instead of `Bash`. The instruction block uses
`exec curl` syntax which OpenClaw understands natively. When using `--local openclaw`,
credentials are written to `~/.openclaw/skills/gstackbrowse-remote.json`.


### Codex

Codex agents can execute shell commands via `codex exec`. The instruction block's
curl commands work directly. When using `--local codex`, credentials are written
to `~/.codex/skills/gstackbrowse-remote.json`.

### Cursor

Cursor's AI can run terminal commands. The instruction block works as-is.
When using `--local cursor`, credentials are written to
`~/.cursor/skills/gstackbrowse-remote.json`.

## Revoking access

To disconnect a specific agent:

```bash
$B tunnel revoke AGENT_NAME
```

The command deletes every token for that agent (the session and any pending
setup keys) and re-reads the agent list to prove it's gone.

See who's paired:

```bash
$B tunnel agents
```

Unexchanged setup keys show as "(pending)"; `tunnel revoke` removes them too.

To disconnect ALL agents at once, stop the daemon. Scoped tokens live in
daemon memory and never survive a restart; the next command boots a fresh
daemon with a new root token:

```bash
$B stop
```
