# PR Description Style Guide

This document defines how to write PR descriptions. The structure is **not a rigid template** — it adapts organically to the type and complexity of the change.

## Core Principle: Structure Scales with Complexity

| PR weight | Structure |
|---|---|
| **Trivial** (typo, config tweak, single-line fix) | Empty body or one sentence. The title carries the meaning. |
| **Small** (focused fix, minor refactor) | 1-3 plain prose paragraphs. No section headers. |
| **Medium** (feature, non-trivial fix, dep upgrade) | 2-4 `###` sections chosen from the section catalog below. |
| **Large** (new aggregate, major investigation, breaking change) | Full structured description with design decisions, tests, deployment notes. |

## Core Writing Rules

1. **Problem-first narrative**: Always start with *why*, never with *what you changed*. The reader must understand the problem/need before the solution.
2. **Prose over bullets**: Use paragraphs, not bullet lists, for context and reasoning. Bullets are acceptable only for enumerating discrete items (files, steps, checklist).
3. **Trade-off reasoning**: When a design decision exists, explain what alternatives were considered and why they were rejected.
4. **Evidence-based**: Include real production errors, stack traces, metrics, or benchmark data when they motivated the change.
5. **No filler**: No "This PR does the following:", no boilerplate intro, no restating the title.

## Section Catalog

Pick only the sections that add value. Never use all of them. Order them as listed.

### `### Context` / `### Problem` / `### Goal`
**When**: Almost always for medium+ PRs.
**What**: The business or technical reason this change exists. For bugs: the observed symptom. For features: what gap this fills. For chores: what triggered the need (deprecation, log noise, dependency conflict).

Include verbatim production errors, log lines, or Slack thread links when they are the trigger.

### `### Root Cause` / `### Investigation`
**When**: Complex bugs where the symptom is non-obvious.
**What**: The technical investigation. May include:
- Hypotheses tested (table format: hypothesis | result)
- Metrics/observations (tables with numbers)
- Race condition timelines (ASCII diagrams showing concurrent flows)
- MySQL/infra behavior explanations with documentation quotes

### `### Changes` / `### What this PR does` / `### Fix` / `### Solution`
**When**: When the change isn't self-evident from the diff.
**What**: Technical description of the approach. Include before/after code snippets for fixes. Explain the architectural reasoning, not just what files were touched.

### `### Key Design Decisions`
**When**: Large features with non-obvious architectural choices.
**What**: Each decision as a bullet with the reasoning. Explicitly state the rejected alternative and why it's unsafe/wrong.

Example pattern:
> * Sources are carried in the event, not re-read from the Search aggregate.
> `SearchRegisteredEvent` now embeds the source list active at registration time. The alternative was to compare the event's revision against the Search's current SearchSettings revision. This is unsafe: [reason].

### `### Out of scope`
**When**: Large features where the reader might expect more.
**What**: What was deliberately NOT included and why. Bold the key statement.

Example:
> **This PR does not fetch anything from the YouTube API.** The handler immediately acknowledges the backfill without calling any external service. This is intentional: the infrastructure needs to be in place and verified before the real fetch logic is wired in.

### `### Breaking changes`
**When**: API changes, field renames, behavioral changes.
**What**: List each breaking change. Be specific about what clients must update.

### `### Tests` / `### Testing`
**When**: Large features with significant test coverage.
**What**: Test coverage summary with concrete numbers (scenarios, steps, test cases). Group by test type (Behat, PHPUnit). Mention edge cases explicitly.

Example:
> - **Behat (`youtube-matches-backfill`)**: 15 scenarios / 73 steps covering the full state machine
> - **PHPUnit (`FetchYoutubeBackfillMatchesTaskHandlerTest`)**: 6 unit tests, one per main code path

### `### Deployment note` / `### Deployment Steps` / `### Deploy` / `### Post-deploy`
**When**: Migrations, infra changes, env vars, topic creation, process restarts, multi-PR sequencing.
**What**: Concrete actions. Use checklists for multi-step deployments. For multi-PR sequences, number the steps and mark which are done.

Example (multi-PR ordering):
> 1. This PR — apply Terraform to create the secret slot
> 2. Ops populates the secret value in Scaleway Secret Manager
> 3. Second PR (#830) — deploy Ansible changes that inject the secret at runtime

Include safety notes: "non-destructive schema change", "online DDL, concurrent reads continue uninterrupted".

### `### Notes` / `### Additional Notes` / `### References`
**When**: Upstream links, related documentation, future considerations.
**What**: Links to upstream commits, Slite docs, official documentation. Brief notes about future improvements (e.g., "evaluating the extension-based alternative can be done separately").

## Patterns by PR Type

### Bug fix
- **Trivial**: empty body or one sentence.
- **Substantial**: `### Context` (symptom with real error) → root cause analysis → `### Fix` (with code snippet) → `### Deployment note` if needed.
- **Complex**: Full investigation narrative with hypotheses table, race condition diagram, or metrics. See "Root Cause / Investigation" section above.

### Feature
- **Small**: 1-2 paragraphs of context + what was built.
- **Large**: `### Context/Goal` → `### Changes` → `### Key Design Decisions` → `### Out of scope` → `### Tests` → `### Deployment Steps`.

### Dependency upgrade
`### Context` (what triggered: bug, deprecation, log noise) → `### Changes` (version old → new) → `### Breaking changes` (if any, with how they were fixed) → `### Deployment note` (cache clearing, restarts).

### Chore / Refactor
Brief context + what changed. Keep it short. Add `### Notes` only if there's a non-obvious subtlety.

### Revert
`Reverts org/repo#N` + one sentence explaining why the revert was needed.

## Visual Aids

Use these when they genuinely clarify:
- **Tables**: for benchmark comparisons, metrics, hypothesis results, version changes.
- **ASCII timelines**: for race conditions or concurrent flow explanations.
- **Code blocks**: for before/after fixes, error messages, stack traces, CLI commands.
- **Screenshots**: for UI-related context (use GitHub image markdown).
- **Checklists**: for deployment steps.

## Cross-Referencing

Link to related context when it exists:
- Related PRs: full GitHub URL or `#NNN` shorthand
- Shortcut tickets: already in the title as `[sc-XXXXXX]`
- Slack threads: full Slack archive URL
- Upstream commits/issues: full GitHub URL
- Internal docs: Slite links
