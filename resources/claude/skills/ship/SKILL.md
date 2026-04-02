---
name: ship
description: Take an idea or ticket from exploration to a draft PR — investigate, plan approaches, create Shortcut ticket, implement, and open a PR
argument-hint: <ticket-id or idea description>
disable-model-invocation: true
effort: high
---

# Investigate

You are a senior staff software engineer conducting a thorough **read-only investigation** before any implementation begins. Your goal is to explore an idea, understand the codebase impact, and present 2-3 possible approaches with trade-offs.

**Phases 0–5 are strictly read-only** — no files created, no branches, no external writes.
Phases 6–7 create a Shortcut ticket and optionally implement. Both are gated by explicit user confirmation.

## Phase 0: Parse Input

- If `$ARGUMENTS` is empty: use `AskUserQuestion` to ask what to investigate
- If `$ARGUMENTS[0]` matches a number (e.g. `186442`) or a Shortcut ID (e.g. `sc-186442`, `SC-186442`): treat it as a **Shortcut ticket ID** — strip the `sc-` prefix if present, then fetch the ticket using `mcp__shortcut__stories-get-by-id` with `full: true`
- Otherwise: treat the full arguments string as a **free text idea description**

## Phase 1: Understand the Problem

- If Shortcut ticket: summarize the requirement from the ticket (title, description, type, labels, comments)
- If free text: restate the idea in your own words
- Identify the core problem, expected behavior, and constraints
- Present this summary to the user and confirm understanding before proceeding

## Phase 2: Ask Clarifying Questions

Use `AskUserQuestion` to ask **2-4 questions in a single batch**. Always provide multiple-choice options. Focus on:

- **Scope boundaries**: what's in scope vs out of scope
- **Approach preferences**: performance vs simplicity, new patterns vs existing ones
- **Integration points**: which systems or contexts are involved
- **Constraints**: timeline, backwards compatibility, deployment concerns

## Phase 3: Explore the Codebase

Investigate thoroughly using read-only tools (Read, Grep, Glob, LSP). For each relevant area:

- Identify affected bounded contexts under `src/Ingestor/`
- Find similar existing patterns (aggregates, commands, event handlers) to mirror
- Trace code paths using LSP (goToDefinition, findReferences, incomingCalls)
- Check existing tests (Behat features + PHPUnit tests) in the affected area
- Review recent git history for the affected files

**Never speculate about code you have not opened.** Only make claims about code you have actually read.

## Phase 4: Present 2-3 Approaches

For **each approach**, present:

| Section | Content |
|---------|---------|
| **Summary** | One-sentence description of the approach |
| **How it works** | Step-by-step explanation |
| **Affected files** | List of files that would be created or modified |
| **Mirrors pattern in** | Existing code paths this approach follows (with file paths) |
| **Pros** | Advantages of this approach |
| **Cons** | Disadvantages and risks |
| **Effort** | Small / Medium / Large |

Always present at least 2 approaches. Never present a single approach without alternatives.

## Phase 5: Recommendation

Conclude with:

1. **Recommended approach** and why (prefer simplicity)
2. **Risks and open questions** that remain
3. **Testing strategy** (which test types, what scenarios to cover)
4. **Critical files to read** before starting implementation (file paths the implementer must understand)

## Phase 6: Create Shortcut Ticket

Use `AskUserQuestion` to ask in a single batch:
- Which **epic** to attach this story to (offer to list recent epics via `mcp__shortcut__epics-search` if needed)
- **Story type**: feature, bug, or chore

Then:
1. Get current user: `mcp__shortcut__users-get-current`
2. Create the story with `mcp__shortcut__stories-create`:
   - `name`: concise title derived from the investigation topic
   - `description`: structured markdown built from the investigation output:

     ```
     ### Context
     {problem summary from Phase 1}

     ### Approach
     {recommended approach: summary, how it works, affected files}

     ### Testing
     {testing strategy from Phase 5}
     ```

   - `type`: from user answer
   - `team`: `6810ed64-0029-4375-a9f7-c94cb773ab97`
   - `epic`: from user answer
   - `owner`: current user ID
3. Report the ticket URL and ID.

## Phase 7: Implement?

Ask the user (via `AskUserQuestion`): "Ticket created. Do you want me to implement it now?"

**If yes:**
1. Determine branch prefix from story type: feature → `feature`, bug → `bug`, chore → `chore`
2. Create branch from up-to-date master:
   ```bash
   git fetch origin
   git switch -c {type}/sc-{id} origin/master
   ```
3. Move ticket to In Progress: `mcp__shortcut__stories-update` with `workflow_state_id: 500143682`
4. Implement the **recommended approach** from Phase 5 (re-read the critical files identified there first)
5. Run tests and static analysis in the PHP container:
   ```bash
   docker exec ingestor-php_cli-1 php .composer/bin/phpunit [relevant test path]
   docker exec ingestor-php_cli-1 ./tools/phpstan.sh
   ```
6. Fix any failures before proceeding. Do not skip or ignore failures.
7. Use the `/commit` skill to generate and create the commit.
8. Use the `/pr` skill to create the draft PR — pass the ticket ID as the argument.

**If no:** End the session. The ticket URL is already reported above.

## Guiding Principles

- **Read-only through Phase 5**: do not create files, branches, or make any changes until Phase 6
- **No speculation**: only reference code you have actually read
- **Simplicity first**: recommend the simplest approach that solves the problem
- **DDD compliance**: respect bounded context boundaries, follow existing patterns
- **Always present alternatives**: minimum 2 approaches, even if one is clearly better
- **Grounded answers**: every claim about the codebase must reference a specific file path
