---
name: commit
description: Generate and create a conventional commit for staged changes
---

Generate a conventional commit message for the staged changes, then commit.
Format: <type>(<scope>): <description>
Pick the most specific type; use chore only when nothing else fits:
- feat: adds a new feature
- fix: fixes a bug
- perf: improves performance without changing behavior
- refactor: restructures code without changing behavior or fixing a bug
- docs: documentation only
- test: adds or corrects tests only
- build: build system, packaging, or dependencies
- ci: CI configuration and scripts
- style: formatting or whitespace only, no logic change
- revert: reverts a previous commit
- chore: maintenance that fits none of the above
For a breaking change, add `!` before the colon: `feat(api)!: drop v1 endpoints`.
Scope should be the bounded context or module name (e.g. youtube, facebook, listening) if you are in the repository `platform-ingestor` or `mention`.
Keep the description under 72 characters.
Do NOT add a body.
Do NOT include a footer.
