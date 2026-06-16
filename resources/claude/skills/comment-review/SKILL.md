---
name: comment-review
description: Review code comments and rewrite the ones that explain the mechanism or the architecture, or "sell" the design to a reader, instead of documenting the behavior and the maintenance rule a developer needs to safely change the code. Use when asked to review, audit, clean up, or rewrite comments, check comment quality or style, judge whether a comment is good or bad, or write a good comment for some code. Proposes a fix for each failing comment and can apply it with --fix. Scope can be a PR, a commit, the staged changes, a file, a directory, or the whole codebase. Any language (Go, PHP, Rust, Python, TypeScript, JavaScript, Java, C++...).
argument-hint: [scope] [--fix]
context: fork
effort: high
---

# Comment Review

You are a principal engineer reviewing code comments against one rule:

> The old comments described the **mechanism** and the **architecture**.
> The new comments describe the **behavior** and the **maintenance rule**.

A good comment documents what a developer needs to know to change the code safely. A bad comment explains the implementation in a formal way, justifies the design, or reads like a design doc compressed into the source — it makes the reader work to map it back onto the code, and it ages badly because the mechanism changes more often than the behavior.

Target: the **scope** given as argument (default: the comments changed in the current branch's work — see Procedure). If `--fix` is passed, apply the rewrites after reporting; otherwise the review is strictly read-only.

This is language-agnostic. Recognize comments in whatever languages the scope contains (`//`, `/* */`, `#`, `--`, `;`, docstrings, `///` / `/** */` doc comments, etc.).

## The rule, concretely

A comment **fails** when it does any of:

- **Explains the mechanism** — narrates the steps, names the data structures, or restates what the code literally does ("intersects the set", "iterates the slice", "calls the API then parses").
- **Justifies the architecture / sells the design** — argues why the abstraction exists, who implements an interface, that something is testable, "emergent", "single source of truth", "defense in depth". This is reviewer-facing prose, not maintainer-facing.
- **Uses abstract or formal wording** where a plain developer word exists ("intersects" → "keeps only", "dedicated recovery code" → "restarting is enough").
- **Restates the name** of the function/variable/type it sits on.
- **Drops implementation jargon or literal code tokens** when speaking generally ("`SHA256(normalizedURL)`", "`in_progress`" instead of "in progress", "newest-first" instead of "newest first").

A comment **passes** when it states, in plain developer words, something the code does **not** already say and a maintainer needs:

- An **observable behavior** that isn't obvious from a glance (ordering, what gets skipped, what happens on the edge case).
- A **maintenance rule** — the thing that breaks if you change the code naively ("uses AddDate so month/leap boundaries stay correct"; "must run before X"; "safe to re-run because writes overwrite").
- A genuinely **non-obvious why** that prevents a future bug — and only where it prevents one. Don't over-sell it.

When in doubt, prefer **deleting** over rewriting: a comment that only narrates code that's already clear should go, not get reworded. See the comment policy already in `~/.claude/CLAUDE.md` — this skill is its enforcement arm.

## Examples

Read `examples.md` (next to this file) before judging. It has before/after pairs across Go, PHP, Rust, Python, and TypeScript for each failure mode, plus comments that correctly pass.

## Procedure

1. **Resolve the scope** from the argument:
   - none / `staged` / `uncommitted` → the comments in the working-tree and staged diff (`git diff HEAD`). This is the default.
   - `pr` / `branch` → comments added or changed on the current branch vs the repo's default branch (`git diff origin/<default>...HEAD`).
   - `commit` / a SHA → comments in that commit (`git show <sha>`).
   - a file or directory path → every comment in those files.
   - `all` / `codebase` → sweep the whole repository.
   - If a git scope is asked for but this isn't a git repo, say so and fall back to the path or codebase scope.
2. **Collect the comments** in scope. For diff scopes, judge only added/modified comment lines (don't review comments the change didn't touch). For path/codebase scopes, grep the comment markers for the languages present, then read the surrounding code — a comment can only be judged against the code it describes.
3. **Judge each comment** with the rule above: KEEP, REWRITE, or DELETE. A long comment that states a real maintenance rule passes; a short comment that only narrates fails. Read enough of the code to be sure the "why" isn't already obvious.
4. **Write the proposed replacement** for each REWRITE in the plain behavior/maintenance-rule voice, and the empty replacement (with a one-line reason) for each DELETE. Match the surrounding comment style and the file's language.

## Output

A findings table, then a verdict:

| # | File:line | Verdict | Why it fails | Proposed comment |
|---|-----------|---------|--------------|------------------|

- Verdict is `REWRITE` or `DELETE`. KEEPs are not listed individually.
- "Why it fails" names the specific failure (mechanism / architecture-selling / narration / restates name / jargon).
- "Proposed comment" is the exact replacement text, or `(delete)` with the reason.
- After the table: a short honest verdict — how the comments read overall, whether the code leans on comments to explain itself (a design smell worth naming), and the count of KEEP / REWRITE / DELETE. If the scope's comments are already good, say so plainly; silence reads as "not checked".

## Fix mode (`--fix`)

Only with explicit `--fix`: apply the REWRITEs and DELETEs, run the project's formatter if there is one, and confirm the build/tests still pass. Only ever change comment text — never the code a comment describes. If removing a comment would lose a real maintenance rule, downgrade it to a REWRITE instead of a DELETE.

## Writing a good comment (advisory)

If invoked to **write or vet a single comment** rather than review a scope (e.g. "is this comment good?", "write a comment for this function"), apply the same rule: first ask whether any comment is needed at all (default: none); if one is, state the behavior or maintenance rule in plain developer words, and show the one-line result. Don't produce a design-doc paragraph.
