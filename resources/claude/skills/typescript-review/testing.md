# TypeScript Testing Review Rules

Grounded in the Vitest docs (fake timers, `vi.waitFor`, `expect.poll`, module mocking, type testing), Kent C. Dodds ("Testing Implementation Details", "Write tests. Not too many. Mostly integration.", "Avoid Nesting When You're Testing", "AHA Testing"), the MSW philosophy docs, and fast-check. Tests prove behavior and catch regressions — they don't pad volume. Examples use Vitest; the same rules apply to Jest and `node:test` with their equivalents.

## 1. General expectations

A review asks:
- what behavior changed?
- what branch, invariant, or error path changed?
- what breaks if this is wrong?
- do the tests prove the new behavior, including the failure paths?

### The mutation check

Existence of a test is not coverage. For each fix in the diff, revert it — mentally or actually — and name the test that fails. If none fails, the fix is untested no matter how many tests surround it. Apply the same check to tests the PR *modifies*: an assertion flipped to match new behavior should fail against the old behavior.

Then ask whether the assertion can observe the defect at all. A test whose input exercises the changed path but whose assertions only cover the invariant part of the output cannot fail for the right reason. Recurring shapes:

- assertions on `toHaveLength` or `toBeDefined`, when the defect corrupts item *content*
- `toHaveBeenCalled()` when the bug is in the arguments
- a fixture that never sets the interesting field to `0`, `""`, or `false`, so a `||` vs `??` or truthiness bug cannot show
- a case where the changed branch is never reached, so the assertion holds either way
- a snapshot regenerated in the same PR: it asserts only that the output equals itself

## 2. Structure

### Strong defaults

- Test names state behavior: `it("returns an empty list when the query is blank")`, not `it("works")` or `it("getUsers")`.
- No shared mutable state between tests. A top-level `let` reassigned in nested `beforeEach` blocks forces the reader to replay the hooks in their head; build what the test needs inline or with a factory (`setup(overrides)`), so each test shows only what makes it different. Hooks are for cleanup. (Dodds, "Avoid Nesting".)
- One framework and one style per file.

### Review questions

- Can I understand this test without scrolling to a `beforeEach`?
- Does one test's leftover state change another's result?

## 3. Parameterize over copy-paste

### Strong defaults

- Multiple input/output cases belong in `it.each` / `test.each`, not copy-pasted near-identical tests. Near-duplicate test bodies are a finding.

```ts
it.each([
  { input: "", expected: 0 },
  { input: "ts", expected: 2 },
  { input: "héllo", expected: 5 },
])("counts $expected characters in '$input'", ({ input, expected }) => {
  expect(charCount(input)).toBe(expected);
});
```

- For a function with a real input space (parsers, encoders, anything with a round-trip or an invariant), a property-based test (fast-check) finds the cases nobody thought to list and shrinks the counterexample.

## 4. Useful assertions

### Hard rules

- Assert the value, not its existence: `expect(user.name).toBe("Ada")`, not `expect(user).toBeTruthy()` or `toBeDefined()`. `toEqual` / `toStrictEqual` on the whole result beats three partial checks.
- Assert errors by type and message, and make sure the assertion runs:
  ```ts
  await expect(createUser({ id: -1 })).rejects.toThrow(/id must be positive/);
  ```
  A `try { … } catch (e) { expect(e)… }` with no failure on the non-throwing path passes when nothing throws.
- Every promise-based assertion is awaited or returned. An un-awaited `expect(…).resolves` / `.rejects` finishes after the test has passed.
- No assertion that cannot fail: asserting a mock returns what it was just told to return, `expect(true).toBe(true)`, or an assertion inside a callback that may never be invoked (guard those with `expect.assertions(n)` or `expect.hasAssertions()`).

### Strong defaults

- Snapshots only for small, stable, reviewed output. A large snapshot is approved without being read.

## 5. Error & edge paths

### Hard rules

- Test the rejection and error paths, not just the happy path.
- A bug fix needs a regression test that fails before the fix.
- Cover the boundaries the types allow: empty array, `undefined` vs absent, `0` / `""` / `false` where they are valid, a single element, duplicate keys, input at the size limit.

## 6. Test behavior, mock at the seams you own

### Hard rules

- Test through what a consumer of the unit can observe — its return value, its rendered output, the calls it makes across a boundary it owns — not its internals. A test that breaks on a refactor that preserved behavior, or passes when behavior broke, is testing implementation details. (Dodds.)
- Mock at a seam the consumer owns (a repository, a gateway, a clock, an HTTP boundary), not a value object and not the unit's own internals. For HTTP, intercept at the network level (MSW) and describe the server's behavior rather than stubbing `fetch` call by call.
- Don't add an exported function, method, or accessor to production code solely so a test can observe internal state. Observe through a fake or the public behavior.
- Prefer an injected fake to a module mock. `vi.mock` is hoisted, global to the file, and cannot intercept a call within the same module; a collaborator passed as an argument needs none of that.
- Restore what a test replaces: `vi.restoreAllMocks()` / `restoreMocks`, `vi.unstubAllEnvs()`, `vi.unstubAllGlobals()`, `vi.useRealTimers()`.

### Strong defaults

- Keep fixtures honest about types. An `as any` or `as unknown as User` fixture stops the compiler from telling you the real type changed, so the test keeps passing against a shape production no longer produces. Build a complete value with a factory, type a partial with `Partial<T>` plus defaults, and use `vi.mocked(fn)` for typed mocks.
- "Write tests. Not too many. Mostly integration." A few tests through the real collaborators give more confidence than many that mock everything around one function. (Dodds.)

### Review questions

- Would this test survive a refactor that keeps behavior identical?
- Is a value type or an unowned module being mocked where a real instance would do?
- Was a production export added just for the test?

## 7. No sleeps as synchronization

### Hard rules

- **Never** wait a fixed time — `await new Promise(r => setTimeout(r, 100))`, a `sleep` / `delay` helper, `page.waitForTimeout` — as a synchronization or assertion barrier. It is slow when it works and flaky when it doesn't. Wait on a condition:
  - fake timers advanced explicitly, for code that schedules time:
    ```ts
    vi.useFakeTimers();
    const result = retryWithBackoff(op);
    await vi.advanceTimersByTimeAsync(3_000);
    await expect(result).resolves.toBe("ok");
    ```
  - a deadline-bounded poll, for a state that becomes true: `await expect.poll(() => queue.size).toBe(0)` or `await vi.waitFor(() => expect(spy).toHaveBeenCalledOnce())`,
  - an awaited signal from a fake: a promise the fake resolves when called (`Promise.withResolvers()`), or
  - an injected clock, rather than `Date.now()` read directly.
- Use the async timer APIs (`advanceTimersByTimeAsync`, `runAllTimersAsync`) when the code under test awaits between timers; the synchronous ones don't flush promise callbacks.

### Review questions

- Could this test flake because it waits a fixed time or reads the real clock?
- Is time controlled by fake timers or an injected clock?

## 8. Isolation

### Hard rules

- Tests don't depend on the network, a shared database, the real clock, the time zone, locale, or test order. A test that passes only in the author's time zone is a finding (see `Date` in `correctness-concurrency.md`).
- An assertion that throws inside an un-awaited promise or an event callback fails nothing. Collect the result back into the test and assert there.

## 9. Type-level tests

### Strong defaults

- An exported generic, conditional, or overloaded type is behavior and gets a test: `expectTypeOf(fn).returns.toEqualTypeOf<Expected>()` in a `*.test-d.ts` file run in typecheck mode.
- `// @ts-expect-error` as a negative test passes for *any* error on that line, including a typo. Keep it on the narrowest expression and say what error is expected.

## 10. What makes missing tests blocking

Usually blocking:
- a bug fix with no regression test, or with a test that passes with the fix reverted
- a new branch or error path with only happy-path coverage
- an async or concurrency change with no test exercising the new path
- a behavior change on a critical path with no meaningful assertion
- a fixed-time sleep used as a synchronization barrier
- an un-awaited async assertion, or an assertion that cannot fail
- a production export added only for a test

Usually suggestion:
- a refactor with preserved behavior but no added tests
- weak assertions (`toBeTruthy`, `toBeDefined`, `toHaveBeenCalled`) where the value should be checked
- copy-paste tests that should be `it.each`
- a module mock where an injected fake would do; mocking a value type
- an `as any` / `as unknown as` fixture
- no type-level test for an exported generic

Usually nit:
- test naming, assertion wording
- factory or helper extraction

## 11. Review wording

Don't say only "missing tests". Say: what behavior is unproven, why it matters, and what test would close the gap.
