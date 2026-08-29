# tstack — Agent Role Definitions

tstack agents are specialized AI roles for software development. Each agent has a specific focus and set of responsibilities.

## Available Agents

### Planning Agents

#### `ceo-reviewer`
- **Focus:** Product strategy, market fit, user value
- **When to use:** Before writing code, when scoping a new feature
- **Skills used:** `/office-hours`, `/plan-ceo-review`

#### `eng-reviewer`
- **Focus:** Architecture, data flow, edge cases, tests
- **When to use:** Before implementing a feature, when reviewing a plan
- **Skills used:** `/plan-eng-review`

#### `design-reviewer`
- **Focus:** Visual design, UX, hierarchy, spacing
- **When to use:** When building UI, when reviewing design decisions
- **Skills used:** `/plan-design-review`, `/design-review`

#### `devex-reviewer`
- **Focus:** Developer experience, onboarding, documentation
- **When to use:** When building tools, when reviewing DX
- **Skills used:** `/plan-devex-review`, `/devex-review`

### Implementation Agents

#### `qa-lead`
- **Focus:** Testing, bug finding, verification
- **When to use:** After implementing a feature, before shipping
- **Skills used:** `/qa`, `/qa-only`

#### `release-engineer`
- **Focus:** Deployment, CI/CD, versioning
- **When to use:** When shipping a feature, when setting up deploy
- **Skills used:** `/ship`, `/land-and-deploy`, `/setup-deploy`

#### `debugger`
- **Focus:** Root cause analysis, systematic investigation
- **When to use:** When investigating a bug, when stuck
- **Skills used:** `/investigate`

### Security Agents

#### `security-auditor`
- **Focus:** OWASP Top 10, STRIDE, vulnerability scanning
- **When to use:** Before shipping, when reviewing security
- **Skills used:** `/cso`

## Agent Invocation

Agents are invoked via skills. For example:
- `/plan-ceo-review` invokes the CEO reviewer agent
- `/qa` invokes the QA lead agent
- `/cso` invokes the security auditor agent

## Custom Agents

To create a custom agent:
1. Add a new file in `agents/your-agent-name.md`
2. Define the agent's focus, when to use, and skills used
3. Reference it from the relevant skill
