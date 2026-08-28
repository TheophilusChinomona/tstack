# Security Remediation Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Remediate the confirmed security findings from the gstack audit in `TheophilusChinomona/gstack`, with the highest priority on preventing repository-controlled browser skills from receiving credentials and on eliminating vulnerable dependencies and CI supply-chain exposure.

**Architecture:** Preserve the existing capability-based browser security model, but make trust elevation an explicit operator decision rather than a repository-controlled frontmatter flag. Keep project and agent-authored skills in the scrubbed environment by default. Upgrade vulnerable runtime dependencies through the owning packages, pin all GitHub Actions to immutable commit SHAs, and add regression gates so the vulnerabilities cannot silently return.

**Tech Stack:** TypeScript, Bun, Bun test, Playwright, GitHub Actions, `bun.lock`, Windows/Linux/macOS CI.

---

## Findings covered

- **SEC-01 High:** `.gstack/browser-skills/<name>/SKILL.md` can set `trusted: true`; `browse/src/browser-skill-commands.ts` then passes nearly all of `process.env` to repository-controlled code.
- **SEC-02 High:** production dependency graph contains vulnerable `protobufjs@7.5.5` and `sharp@0.34.5` through `@huggingface/transformers`.
- **SEC-03 High:** `.github/workflows/pr-title-sync.yml` is `pull_request_target` with `pull-requests: write` and uses mutable `actions/checkout@v7`.
- **SEC-04 Medium:** production dependency graph contains vulnerable `ip-address@10.2.0` via `socks` and `image-size@1.2.1` via `html-to-docx`.
- **Verification debt:** targeted security tests currently have Windows-specific file-URL expectation failures and one spawned-skill PATH failure.

## Non-goals

- Do not weaken the existing scoped-token, SSRF, path-validation, or content-boundary controls.
- Do not add blanket network blocking that breaks legitimate browser automation.
- Do not commit secrets, modify `.env` files, rewrite history, or merge/push to upstream.
- Do not treat `bun audit` advisory names as proof that every vulnerable code path is reachable; validate runtime reachability and retain defense-in-depth upgrades regardless.

---

### Task 1: Establish a remediation branch and baseline

**Objective:** Create an isolated implementation branch in the fork and record reproducible baseline results.

**Files:**
- Modify: none
- Test: `browse/test/browser-skill-commands.test.ts`, `browse/test/url-validation.test.ts`

**Steps:**
1. From `C:/Users/Givemore/Desktop/Theo/Skills and plugins/gstack-theophilus`, verify `origin` is `https://github.com/TheophilusChinomona/gstack.git` and `upstream` is `https://github.com/garrytan/gstack.git`.
2. Create a branch named `security/remediation-audit-findings`.
3. Run `bun audit --audit-level=moderate --json` and save only non-secret package/version/advisory metadata to the review notes.
4. Run the targeted security suite and record the current failures without changing tests yet.
5. Commit only if the branch setup requires a repository-visible change; otherwise leave the branch clean.

**Verification:** `git status --short`, `git branch --show-current`, and the baseline test/audit commands are reproducible.

---

### Task 2: Define the browser-skill trust policy with failing tests

**Objective:** Prove that repository/project and agent-authored skills cannot self-elevate to full environment access.

**Files:**
- Modify: `browse/test/browser-skill-commands.test.ts`
- Inspect: `browse/src/browser-skills.ts`, `browse/src/browser-skill-commands.ts`

**Steps:**
1. Add a test for a project-tier skill whose frontmatter contains `trusted: true`; assert its spawn environment is scrubbed.
2. Add a test for an agent-authored skill with `trusted: true`; assert it is scrubbed unless an explicit trust decision is supplied by the caller.
3. Add a test that global/bundled trusted skills retain the documented policy only when the explicit trust decision is true.
4. Add a test that the child never receives `GSTACK_TOKEN`, provider keys, cloud keys, SSH keys, or other keys matching the existing secret patterns.
5. Run the new tests and confirm they fail against the current implementation.

**Expected failure:** project/agent skills currently pass the `trusted` frontmatter value directly into `spawnSkill`.

---

### Task 3: Enforce explicit trust at the spawn boundary

**Objective:** Make trust elevation an explicit, non-repository-controlled input.

**Files:**
- Modify: `browse/src/browser-skill-commands.ts:146-157,326-454`
- Modify: `browse/src/browser-skills.ts:32-57,154-163`
- Test: `browse/test/browser-skill-commands.test.ts`
- Possibly modify: command/context types in `browse/src/meta-commands.ts` if the explicit decision must be threaded through command dispatch.

**Steps:**
1. Keep frontmatter `trusted` as descriptive metadata, but do not treat it as authorization.
2. Add a trust-decision field that is supplied by an operator-controlled caller, not by `SKILL.md`.
3. Default every project and agent-authored skill to the scrubbed environment.
4. Require an explicit user-approved path for trusted global/bundled skills, or conservatively keep all CLI skill runs scrubbed until such approval exists.
5. Preserve the scoped `GSTACK_PORT` and per-spawn `GSTACK_SKILL_TOKEN` injection.
6. Ensure the trusted environment path still strips `GSTACK_TOKEN` and any other daemon root credential.
7. Add a clear audit/log message when a skill is denied trust elevation; never log secret values.
8. Run the focused tests and confirm the new policy tests pass.

**Security requirement:** a project-controlled `SKILL.md` must never be able to turn a child process into a credential-bearing process by changing only frontmatter.

---

### Task 4: Add skill trust documentation and static regression gates

**Objective:** Make the trust boundary visible and enforceable during future changes.

**Files:**
- Modify: `browse/src/browser-skills.ts` comments
- Modify: `browse/src/browser-skill-commands.ts` comments
- Modify: `browse/test/server-security-surface.test.ts` or a new focused security test
- Inspect/update: relevant `browse/SKILL.md` or generated source template if the command behavior is documented there

**Steps:**
1. Document that project and agent skills are untrusted code, even when frontmatter says `trusted: true`.
2. Document exactly what an explicit trust decision means and where it can originate.
3. Add a static tripwire rejecting code that passes `skill.frontmatter.trusted` directly to `spawnSkill` or `buildSpawnEnv` as authorization.
4. Add an end-to-end test using a synthetic project skill that attempts to read a sentinel environment secret and proves it is absent.
5. Run `bun test browse/test/browser-skill-commands.test.ts browse/test/server-security-surface.test.ts`.

---

### Task 5: Upgrade runtime dependency vulnerabilities

**Objective:** Remove vulnerable production packages without relying on an audit suppression.

**Files:**
- Modify: `package.json` only if direct dependency constraints must change
- Modify: `bun.lock`
- Test: existing screenshot, transformer/security-sidecar, SOCKS bridge, and PDF/image tests

**Steps:**
1. Determine the newest compatible `@huggingface/transformers` release that resolves vulnerable `protobufjs` and `sharp` versions.
2. Determine the newest compatible `socks` release that resolves the `ip-address` SSRF parsing advisories.
3. Determine the newest compatible `html-to-docx` release or safe override that resolves `image-size` parser DoS advisories.
4. Update dependencies with Bun, preserving the existing `playwright-core` patch and `adm-zip` override.
5. Run `bun pm ls --all` and verify the vulnerable versions are absent from the production dependency graph.
6. Run `bun audit --audit-level=high --json`; distinguish remaining development-only advisories from production findings.
7. Run focused tests for `screenshot-size-guard`, `security-sidecar`, `socks-bridge`, and make-pdf image handling.
8. If an upstream package cannot yet be upgraded, isolate the parser in a constrained subprocess or add a narrowly scoped temporary override with an issue reference and expiry condition.

**Acceptance criteria:** no high-severity production advisory remains for `protobufjs`, `sharp`, `ip-address`, or `image-size`, unless an explicit, documented reachability analysis proves the package is not shipped or executed.

---

### Task 6: Pin all GitHub Actions immutably

**Objective:** Remove mutable-action supply-chain risk, especially from the write-capable `pull_request_target` workflow.

**Files:**
- Modify: every workflow under `.github/workflows/` that uses mutable action tags
- Test: `test/pr-title-sync-workflow-safety.test.ts` and a new action-pinning test if needed

**Steps:**
1. Resolve the exact commit SHA for each used action tag through GitHub’s repository metadata.
2. Replace mutable references such as `actions/checkout@v7`, `actions/cache@v6`, and upload/download action tags with full commit SHAs and retain version comments.
3. Keep `.github/workflows/pr-title-sync.yml` base-only checkout and env-based attacker-controlled fields unchanged.
4. Add a static test that rejects third-party action references not pinned to a 40-character commit SHA.
5. Add a specific assertion that `pr-title-sync.yml` uses an immutable checkout reference.
6. Run the workflow safety tests and, if available, `actionlint` in CI.

**Acceptance criteria:** no mutable third-party action reference remains in `.github/workflows/`; the `pull_request_target` workflow has immutable dependencies and no PR-head checkout.

---

### Task 7: Repair Windows security-test failures

**Objective:** Restore the path-validation regression suite to green on Windows without weakening path restrictions.

**Files:**
- Modify: `browse/test/url-validation.test.ts`
- Inspect/possibly modify: `browse/src/url-validation.ts`
- Test: `browse/test/url-validation.test.ts`

**Steps:**
1. Replace assertions that require POSIX-specific error text with platform-neutral security assertions, such as rejection status and safe-path failure semantics.
2. Ensure temporary Windows paths are converted to valid `file:///C:/...` URLs through the existing URL helper rather than interpolated as `file://C:\...` authority-like URLs.
3. Preserve tests for encoded separators, traversal, UNC/network hosts, and files outside `TEMP_DIR`/cwd.
4. Run the URL validation suite on Windows.
5. Run the equivalent Linux/macOS-compatible cases if the code path is shared.

**Acceptance criteria:** all path-security tests pass on Windows and continue to prove traversal/symlink/encoded-separator rejection.

---

### Task 8: Repair spawned-skill Bun resolution test failure

**Objective:** Make the subprocess test harness use the same Bun executable resolution as production without broadening untrusted PATH access.

**Files:**
- Modify: `browse/src/browser-skill-commands.ts:457-465` if production resolution is incomplete
- Modify: `browse/test/browser-skill-commands.test.ts` or test setup
- Test: spawned skill lifecycle suite

**Steps:**
1. Inspect `process.execPath` and the test environment on Windows.
2. Pass an absolute Bun executable path to the child process, or use the existing resolved runtime path rather than relying on `PATH` to find `bun`.
3. Keep untrusted skill PATH minimal and do not add arbitrary user directories.
4. Run the full spawn lifecycle suite, including timeout, token revocation, stdout cap, and scrubbed-environment tests.

---

### Task 9: Full verification and review gate

**Objective:** Verify the fork contains a complete, regression-tested remediation set.

**Commands:**

```bash
bun install --frozen-lockfile
bun audit --audit-level=high --json
bun test browse/test/browser-skill-commands.test.ts browse/test/server-security-surface.test.ts browse/test/url-validation.test.ts browse/test/cdp-allowlist.test.ts browse/test/extension-sender-auth.test.ts
bun run test:audit
bun run test:windows
bun run test
bun run build
```

Also run, when installed:

```bash
actionlint
osv-scanner scan source -r .
```

**Review checklist:**

- Project skills cannot receive secrets through frontmatter.
- Root daemon tokens never enter skill subprocesses.
- Vulnerable production package versions are absent or explicitly justified.
- Every GitHub Action is SHA-pinned.
- `pull_request_target` still executes only base-repository code.
- Windows path-security tests pass.
- Spawn lifecycle tests pass without broadening PATH.
- No `.env`, credential, or generated binary files were changed.

---

### Task 10: Commit, push, and prepare a fork PR

**Objective:** Publish the remediation branch only after all verification gates pass.

**Files:**
- Git history and fork branch only

**Steps:**
1. Review `git diff --check`, `git status --short`, and `git diff --stat`.
2. Run a secret scan over the final diff; do not print secret values.
3. Create focused commits by remediation slice, for example:
   - `fix(security): prevent project skills from self-elevating trust`
   - `fix(deps): upgrade vulnerable runtime parsers`
   - `ci(security): pin GitHub Actions to immutable SHAs`
   - `test(security): restore Windows regression coverage`
4. Push the branch to `origin` in the fork.
5. Open a PR from `TheophilusChinomona/gstack:security/remediation-audit-findings` to the upstream default branch only after explicit review of the generated diff.
6. Report exact branch, commit IDs, PR URL, test results, and any remaining advisory/blocker.

**Safety:** Do not merge the PR, alter upstream settings, or push to the upstream repository.

---

## Risks and tradeoffs

- Removing implicit trust may require a new operator approval UX for legitimate internal skills. The safer interim behavior is scrubbed execution rather than preserving a repository-controlled privilege flag.
- Dependency upgrades may require transformer/model-cache changes or platform-specific native package updates.
- SHA pinning adds maintenance work; Dependabot or Renovate should be configured after remediation to keep immutable references current.
- The audit identified dependency advisories from the current 2026 advisory database; re-run the audit at implementation time because advisory status and patched versions can change.

## Open questions for implementation

1. Should explicit trust be available only for bundled/global skills, or should the product add a user-confirmed trust grant for a specific project skill hash?
2. Is `@huggingface/transformers` required in the production install, or can the security classifier be packaged separately to reduce native parser exposure?
3. Should the final PR target `garrytan/gstack:main`, or should the fork retain a remediation branch for internal review first?
