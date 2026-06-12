# Claude Code Global Memory

## Working Guidelines

1. **Think First**: Think through the problem, read the codebase for relevant files.
2. **Check Before Major Changes**: Before making any major changes, check in with me and I will verify the plan.
3. **High-Level Explanations**: Every step of the way, give me a high level explanation of what changes you made.
4. **Simplicity Above All**: Make every task and code change as simple as possible. Avoid massive or complex changes. Every change should impact as little code as possible. Everything is about simplicity.
5. **Maintain Documentation**: Maintain a documentation file that describes how the architecture of the app works inside and out.
6. **Never Speculate**: Never speculate about code you have not opened. If I reference a specific file, you MUST read the file before answering. Investigate and read relevant files BEFORE answering questions about the codebase. Never make any claims about code before investigating unless you are certain - give grounded and hallucination-free answers.

## Code Comments

Default to zero comments. Before writing one, apply this test: does it state a constraint, invariant, or workaround that a competent engineer could NOT infer from the code itself? If not, delete it.

Never write:
- Comments that narrate what the code does ("// loop over the results", "// return the error")
- Comments that restate the function or variable name
- Comments justifying your change or addressed to a reviewer ("// this matches the README", "// per the spec", "// as discussed")
- Comments cross-referencing docs, tickets, or other files unless the code is wrong without that context
- Summary/section banners, or doc comments on private helpers whose name already says everything
- Words no engineer writes in comments: "gracefully", "robust", "seamlessly", "leverage", "ensure proper", "for clarity"

The only acceptable comments: a surprising invariant or ordering constraint, a workaround for an external bug (with link), or business logic that contradicts intuition. One line, factual, no hedging.

Never re-add a comment I deleted. When in doubt: no comment.

## Tests

- Never use a sleep as synchronization or as an assertion barrier (any language: `time.Sleep`, `time.sleep`, `sleep()`, `usleep`, `thread::sleep`, `setTimeout`). Wait on a condition: a signal from a fake, a synchronous API, or a polling helper with a deadline.
- Never add an exported method or public accessor to production code solely so a test can observe it. Observe through a fake or a test-package hook.
- Tests exist to catch regressions, not to pad volume: no near-duplicate test bodies, no assertions that cannot fail.
- One canonical syntax per construct; match the surrounding file instead of introducing a second idiom.
