---
name: create_pr
description: Create a draft pull request with conventional commit title and structured description
disable-model-invocation: true
---

# Create Pull Request

Create a draft pull request for the current branch, following conventional commit conventions and a structured description format.

## Steps

### 1. Identify the Shortcut ticket

Extract the Shortcut ticket number from the current branch name:

```bash
git branch --show-current
```

The branch name contains the ticket number (e.g. `chore/sc-186442` -> `186442`, `bug/sc-185954-some-desc` -> `185954`). If a ticket number is passed as an argument, use that instead.

### 2. Gather branch context

Run these commands to understand what the PR contains:

```bash
git log origin/master..HEAD --oneline
git diff origin/master...HEAD --stat
git diff origin/master...HEAD
```

### 3. Create the pull request

Use `gh pr create` with the following flags:

- `--draft`
- `--label php`
- `--assignee @me`

### 4. Title format

Follow conventional commit format, under 70 characters:

```
[sc-{ticket-id}] {type}({scope}): {description}
```

Where:
- `type` is one of: `feat`, `fix`, `chore`, `refactor`, `test`, `docs`, `perf`
- `scope` is the bounded context or module affected (e.g. `listening`, `facebook`, `scheduled-task`)
- `description` is a concise lowercase summary of the change

### 5. Body format

Structure the PR body with these sections:

```markdown
### Context

{Plain text explaining the problem, the root cause, and why this change is needed. Write 2-4 sentences as a senior staff engineer would — clear, direct prose. No bullet points.}

### Changes

{Plain text explaining what was changed and the reasoning behind technical decisions. Describe the approach, not a file-by-file diff. No bullet points.}
```

Add a `### Deployment note` section **only** if the change has deployment implications (migrations, feature flags, config changes, infrastructure updates). Omit it entirely otherwise.

### 6. Style guidance

- No bullet points anywhere in the PR description
- Write clear, direct prose — not a changelog
- Focus on the "why" and the reasoning, not just the "what"
- Keep it concise but informative
