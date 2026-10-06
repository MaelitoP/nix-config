---
name: pr
description: Create a draft pull request with conventional commit title and a short behavior-first description. Use this whenever the user wants to open a PR, push changes for review, or is done with implementation and ready for code review, even if they don't say "PR" explicitly.
argument-hint: [ticket-id]
---

# Create Pull Request

Create a draft pull request for the current branch.

## Pre-flight checks

Before proceeding, detect the repo's default branch and verify there is work to open a PR for:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
DEFAULT_BRANCH=${DEFAULT_BRANCH:-master}
```

Abort (and tell the user why) if:
- The current branch **is** the default branch: there's nothing to open a PR from.
- There are **no commits** ahead of `origin/$DEFAULT_BRANCH`.

Use `origin/$DEFAULT_BRANCH` in place of `origin/master` for every git command below.

## Steps

### 1. Identify the Shortcut ticket

Extract from branch name (e.g. `chore/sc-189847` → `189847`, `feature/sc-182756` → `182756`).
If passed as argument, use that. If no ticket found, skip ticket-related steps.

### 2. Fetch Shortcut ticket context (if ticket found)

Use `mcp__shortcut__stories-get-by-id` with the ticket ID to get name + description.
Use this to inform the PR Context and Changes sections.

### 3. Gather branch context

```bash
git log origin/$DEFAULT_BRANCH..HEAD --oneline
git diff origin/$DEFAULT_BRANCH...HEAD --stat
git diff origin/$DEFAULT_BRANCH...HEAD
```

### 4. Detect labels

- Always include: `claude-code-assisted`
- If changed files include paths under `infra/` or ending in `.tf`: add `terraform`
- If changed files include paths under `cd/ansible/`: add `ansible`
- If changed files include `.php` files: add `php`
- Multiple labels are allowed

### 5. Push the branch

If the current branch does not track a remote branch yet (or is behind), push it:

```bash
git push -u origin HEAD
```

### 6. Create the pull request

Use `gh pr create` with:
- `--draft`
- `--assignee @me`
- `--label claude-code-assisted` (always)
- Additional labels from step 4

**Title format:**

```
[sc-{ticket-id}] {type}({scope}): {summary}
```

- `type`: feat, fix, chore, refactor, test, docs, perf
- `scope`: bounded context or module (e.g. youtube, facebook, listening, inference)
- `summary`: the behavior change, not the implementation, in plain words a teammate recognizes six months later, at most 72 characters excluding the `[sc-...]` prefix. Lower case after the colon, no trailing period.
- Name the main change only. No sizes, counts, instance types, versions or parameters (`one L4-1-24G`, `count-gated`), no words coined during the session, no list of several changes. Two changes at most, joined by a shared verb ("add X and Y").
- Good: `feat(inference): provision GPU serving nodes`. Bad: `feat(inference): count-gated gpu-workers pool, one L4-1-24G`.

**Body format:**

Read [pr-description-style.md](pr-description-style.md) before writing the body.

Write the PR description like a teammate explaining the change to another engineer in a review. It must be reviewer-readable, natural and direct. Prefer plain engineering language over formal prose. Do not sound like documentation, a design document, an incident report or an AI-generated summary.

A reviewer should understand in under 30 seconds:

1. what was wrong or missing;
2. what changes after merge;
3. anything important they need to know before approving.

Do not narrate the diff. Do not prove that the work was thorough. Do not include details just because they were discovered during implementation.

Default to 2 short paragraphs and 60 to 120 words. Shorter is better. There is no minimum length. Hard cap: 200 words.

Before writing, identify all facts from the ticket and diff, then discard anything that is not necessary to understand or review the behavior change. Do not add a section, paragraph, list, validation note or deployment note just because the information is available. Run the final deletion pass of the style guide before `gh pr create`.

### 7. After PR creation

If a Shortcut ticket was found, move it to "Tech Review" state:
use `mcp__shortcut__stories-update` with `workflow_state_id: 500143701`.
