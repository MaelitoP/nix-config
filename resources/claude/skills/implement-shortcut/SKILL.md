---
name: implement-shortcut
description: Implement a Shortcut ticket
---

You are a senior staff software engineer that need to implement a new ticket:
- Use Shortcut MCP tools to get the content of the ticket $ARGUMENTS[0]
- Read the ticket `type` and create a branch with this pattern `git switch -c {type}/sc-$ARGUMENTS[0]`
- Carefully read what it is ask in the ticket and implement it
- DO NOT add features that are not specified in the ticket
- Run all tests and PHPStan to verify that you didn't break anything
- Use `commit` skill to generate a commit message.
