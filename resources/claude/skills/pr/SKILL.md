---
name: pr
description: Create a draft pull request with conventional commit title and structured description
argument-hint: [ticket-id]
---

# Create Pull Request

Create a draft pull request for the current branch.

## Steps

### 1. Identify the Shortcut ticket

Extract from branch name (e.g. `chore/sc-189847` → `189847`, `feature/sc-182756` → `182756`).
If passed as argument, use that. If no ticket found, skip ticket-related steps.

### 2. Fetch Shortcut ticket context (if ticket found)

Use `mcp__shortcut__stories-get-by-id` with the ticket ID to get name + description.
Use this to inform the PR Context and Changes sections.

### 3. Gather branch context

```bash
git log origin/master..HEAD --oneline
git diff origin/master...HEAD --stat
git diff origin/master...HEAD
```

### 4. Detect labels

- Always include: `claude-code-assisted`
- If changed files include paths under `infra/` or ending in `.tf`: add `terraform`
- If changed files include paths under `cd/ansible/`: add `ansible`
- If changed files include `.php` files: add `php`
- Multiple labels are allowed

### 5. Create the pull request

Use `gh pr create` with:
- `--draft`
- `--assignee @me`
- `--label claude-code-assisted` (always)
- Additional labels from step 4

### 6. Title format

```
[sc-{ticket-id}] {type}({scope}): {description}
```

- `type`: feat, fix, chore, refactor, test, docs, perf
- `scope`: bounded context or module (e.g. youtube, facebook, listening)
- Under 70 characters total

### 7. Body format

Write the PR description following the style guide in [pr-description-style.md](pr-description-style.md).

Read that file before writing the body. It defines:
- How structure scales with PR complexity (trivial = empty, small = prose, large = structured sections)
- Which `###` sections to use depending on PR type (fix, feat, chore, refactor, revert)
- Writing rules: problem-first narrative, trade-off reasoning, evidence-based, no filler

Use the Shortcut ticket context (if available) and the actual diff to determine the appropriate level of detail.

### 8. After PR creation

If a Shortcut ticket was found, move it to "Tech Review" state:
use `mcp__shortcut__stories-update` with `workflow_state_id: 500143701`.
