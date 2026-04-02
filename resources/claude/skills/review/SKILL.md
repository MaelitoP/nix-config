---
name: review
description: Review the current PR for correctness, DDD boundaries, naming quality, coding conventions, test adequacy, and security risks
disable-model-invocation: true
context: fork
argument-hint: [PR-number or GitHub PR URL]
effort: high
---

# Code Review

Review a pull request. Default to the current branch PR if no argument is given.

## Review principles

- Be direct, precise, and high-signal.
- Prioritize correctness, architecture, and maintainability over style trivia.
- Treat naming as a first-class concern, especially for aggregates, commands, handlers, and value objects.
- Distinguish clearly between:
  - hard rule violations
  - strong defaults
  - preferences / nits
- Do not review from the diff alone. For any non-trivial finding, inspect the surrounding code and usage sites.

## Load these supporting documents first

Read these files before reviewing:

- `ddd.md`
- `coding-practices.md`
- `testing.md`
- `security.md`
- `severity-rubric.md`
- `examples.md`

Use them as the source of truth for repo-specific review standards.

## Setup

```bash
# Accept a PR number or a full GitHub PR URL (e.g. https://github.com/org/repo/pull/123)
INPUT="${1:-}"
PR=$(echo "$INPUT" | grep -oE '[0-9]+$' || gh pr view --json number -q .number 2>/dev/null)

gh pr view "$PR" --json number,title,body,files,additions,deletions,baseRefName,headRefName
gh pr diff "$PR"
```

Then inspect changed files in the repository directly. Open the full files around the changed hunks when needed.

## Review workflow

### 1) Understand the PR first

Before commenting, determine:

- what behavior changed
- what domain concept changed
- whether the PR introduces or changes an aggregate boundary
- whether the naming matches the actual responsibility
- whether tests cover the meaningful behavioral branches

If the PR description is weak, infer intent from the diff and the surrounding code.

### 2) Run 3 review agents in parallel

Spawn 3 parallel Explore agents, each with a distinct lens.

**Agent 1 — Correctness & Security**

Focus on:
- logic bugs
- nullability risks
- broken invariants
- missing guards
- exception handling problems
- injection risks
- escaping issues
- unsafe external requests
- missing timeout / retry considerations
- persistence / transaction hazards

Read: `security.md`, `severity-rubric.md`

**Agent 2 — DDD, Architecture & Naming**

Focus on:
- bounded context violations
- aggregate boundary violations
- command / handler / event rule violations
- persistence leaking into the domain
- wrong ownership of behavior
- misuse of repositories
- aggregate / entity / value object naming
- misleading or implementation-driven names
- weak ubiquitous language

Read: `ddd.md`, `coding-practices.md`, `severity-rubric.md`

This agent must actively challenge naming and propose better alternatives.

**Agent 3 — Tests & Maintainability**

Focus on:
- missing tests
- weak assertions
- missing failure-path coverage
- regression risk without coverage
- brittle fixtures
- style / readability issues
- overly complex control flow
- poor API shape
- unsafe doctrine usage
- conventions from our PHP codebase

Read: `testing.md`, `coding-practices.md`, `severity-rubric.md`

### 3) Merge findings

Merge duplicate findings from the 3 agents.

Rules:
- Prefer fewer, stronger comments over many weak comments.
- Collapse duplicate comments into a single stronger finding.
- Do not surface speculative issues unless clearly labeled with lower confidence.
- Do not invent line numbers. Use exact file and line when available.
- Propose concrete fixes or rename suggestions whenever possible.

## Output format

Start with:

**Verdict** — choose one:
- Not ready to merge
- Ready with fixes
- Looks good

Then output findings grouped by severity:

**Blocking** / **Suggestion** / **Nit**

Each finding must use this format:

```
File: path:line
Title: short issue summary
Why it matters: concrete impact on correctness, architecture, maintenance, testability, or safety
Recommendation: concrete fix, rewrite direction, or rename suggestion
Confidence: high / medium / low
```

If a finding raises a deeper design question that goes beyond rule compliance (e.g. aggregate boundary choice, value object vs entity decision, responsibility ownership), append:

```
→ /expert <one-sentence design question>
```

This signals the author to follow up with the expert skill for a principled design consultation. Only add this when the finding is genuinely a design dilemma, not a clear rule violation.

## Additional rules

- Always comment on naming when it is materially weak, misleading, overloaded, or too technical for the domain.
- For unclear names, propose 1 to 3 better alternatives.
- Do not praise code unless it helps explain why a competing alternative is worse.
- Avoid generic review comments.
- Avoid "could be improved" wording without a concrete recommendation.
- When something is a preference rather than a rule, say so explicitly.
