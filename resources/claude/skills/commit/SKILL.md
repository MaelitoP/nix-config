---
name: commit
description: Generate and create a conventional commit for staged changes
---

Generate a conventional commit message for the staged changes, then commit.
Format: <type>(<scope>): <description>
Types: feat, fix, refactor, ci, docs, test, chore
Scope should be the bounded context or module name (e.g. youtube, facebook, listening) if you are in the repository `platform-ingestor` or `mention`.
Keep the description under 72 characters.
Do NOT add a body.
Do NOT include a footer.
