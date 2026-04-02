---
name: ticket
description: Create a Shortcut story from a description or plan, assigned to current user in the active epic
disable-model-invocation: true
argument-hint: "<description>"
---

# Create Shortcut Ticket

## Steps

### 1. Get current user

Use `mcp__shortcut__users-get-current` to get your user ID.

### 2. Determine title and description

- If `$ARGUMENTS` is provided, use it as the story title
- Check for a recently modified plan file in `~/.claude/plans/` — if one exists and is relevant, use its content as the story description (structured as Context / Changes / Verification)
- Otherwise ask the user for a description via `AskUserQuestion`

### 3. Determine epic and team

Use `AskUserQuestion` to confirm which epic to attach to, or default to the epic of the last story worked on (check recent git branch names for context).

### 4. Determine story type

Ask if unclear: feature, bug, or chore.

### 5. Create the story

Use `mcp__shortcut__stories-create` with:
- `name`: concise title
- `description`: structured markdown (Context / Changes / Verification sections from the plan if available)
- `type`: determined in step 4
- `team`: Mention team `6810ed64-0029-4375-a9f7-c94cb773ab97`
- `epic`: determined in step 3
- `owner`: current user ID from step 1

### 6. Return the ticket URL and ID
