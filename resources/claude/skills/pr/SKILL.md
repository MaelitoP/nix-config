---
name: pr
description: Create a draft pull request with conventional commit title and structured description. Use this whenever the user wants to open a PR, push changes for review, or is done with implementation and ready for code review — even if they don't say "PR" explicitly.
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
- The current branch **is** the default branch — there's nothing to open a PR from.
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
[sc-{ticket-id}] {type}({scope}): {description}
```

- `type`: feat, fix, chore, refactor, test, docs, perf
- `scope`: bounded context or module (e.g. youtube, facebook, listening)
- Under 70 characters total

**Body format:**

Write the PR description following the style guide in [pr-description-style.md](pr-description-style.md).

Read that file before writing the body. It defines:
- How structure scales with PR complexity (trivial = empty, small = prose, large = structured sections)
- Which `###` sections to use depending on PR type (fix, feat, chore, refactor, revert)
- Writing rules: problem-first narrative, trade-off reasoning, evidence-based, no filler

Use the Shortcut ticket context (if available) and the actual diff to determine the appropriate level of detail.

### 7. After PR creation

If a Shortcut ticket was found, move it to "Tech Review" state:
use `mcp__shortcut__stories-update` with `workflow_state_id: 500143701`.
