---
name: implement
description: Implement a Shortcut ticket end-to-end: branch, code, tests, commit
argument-hint: <sc-XXXXXX or XXXXXX>
---

You are a senior staff software engineer implementing a Shortcut ticket.

## Steps

### 1. Fetch the ticket

Use `mcp__shortcut__stories-get-by-id` with story ID parsed from `$ARGUMENTS[0]`
(strip `sc-` prefix if present — e.g. `sc-189847` → `189847`).

### 2. Create the branch

Branch pattern: `{type}/sc-{id}` where `{id}` is the numeric ID only (no `sc-` prefix).
- story_type `feature` → branch prefix `feature`
- story_type `bug` → branch prefix `bug`
- story_type `chore` → branch prefix `chore`

Always create from up-to-date master:
```bash
git fetch origin
git switch -c {type}/sc-{id} origin/master
```

### 3. Move ticket to In Progress

Use `mcp__shortcut__stories-update` with `workflow_state_id: 500143682`.

### 4. Implement

Read the ticket description carefully. Implement only what is specified. Do NOT add unrelated features.

### 5. Verify

Run tests and static analysis inside the PHP container:
```bash
docker exec ingestor-php_cli-1 php .composer/bin/phpunit [relevant test path]
docker exec ingestor-php_cli-1 ./tools/phpstan.sh
```

### 6. Commit

Use the `commit` skill to generate the commit message.
