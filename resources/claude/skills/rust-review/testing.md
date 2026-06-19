# Rust Testing Review Rules

Grounded in the standard test conventions (`#[cfg(test)]`, `#[test]`, doctests), *Effective Rust* Item 30 (write more than unit tests), and the property-testing ecosystem (`proptest`/`quickcheck`).

## 1. General expectations

Tests prove behavior, not restate implementation. A review asks:
- what behavior changed?
- what branch, invariant, or error path changed?
- what breaks if this is wrong?
- do the tests prove the new behavior, including the failure paths?

## 2. Structure & placement

### Strong defaults

- Unit tests live in a `#[cfg(test)] mod tests { use super::*; ... }` block in the same file as the code they test. They may exercise private items.
- Integration tests live in `tests/` and exercise only the public API — they're the proof the public surface works (`C-EXAMPLE` territory).
- Public APIs get **doctests**: `///` examples that compile and run, using `?` not `unwrap` (`C-QUESTION-MARK`). They document *and* test.

### Review questions

- Is a behavior that's only reachable through the public API tested only via private internals?
- Does a new public function have a doctest showing intended use?

## 3. Parameterized cases over copy-paste

### Strong defaults

- Multiple input/output cases: drive them from a table (a slice of `(input, expected)` looped, or `rstest` `#[case(...)]`) rather than copy-pasting near-identical `#[test]` fns. Near-duplicate test bodies are a finding.
- Reach for `proptest`/`quickcheck` when a property should hold across a range of inputs (round-trips, invariants, parser/serializer pairs) — far stronger than a handful of examples.

```rust
#[rstest]
#[case("", 0)]
#[case("go", 2)]
#[case("héllo", 5)]
fn counts_chars(#[case] input: &str, #[case] want: usize) {
    assert_eq!(char_len(input), want, "char_len({input:?})");
}
```

### Review questions

- Is this a pile of near-duplicate `#[test]` fns that should be one parameterized test?
- Would a property test catch a class of bugs the examples miss?

## 4. Useful failure messages

### Hard rules

- Prefer `assert_eq!`/`assert_ne!` (they print both values) over `assert!(a == b)` (prints nothing useful).
- Add a context message when the assert alone won't identify the case: `assert_eq!(got, want, "char_len({input:?})")`.
- For large structs, a diffing assertion (`pretty_assertions::assert_eq!` or `insta` snapshots) gives far more useful output than a bare equality.

## 5. Error & panic paths

### Hard rules

- Test the `Err` paths, not just `Ok`. Assert the *variant*/content (`assert!(matches!(err, LoadError::Parse(_)))`), not just that it errored.
- Use `#[should_panic(expected = "…")]` with the `expected` substring for intended panics — bare `#[should_panic]` can pass for the wrong panic.
- A bug fix needs a regression test that fails before the fix.

## 6. Async tests

### Hard rules

- Async tests use `#[tokio::test]` (or the runtime's equivalent); pick `#[tokio::test(flavor = "multi_thread")]` deliberately when the test needs real parallelism.
- The same async correctness rules apply in tests — no blocking calls on the runtime, no lock held across `.await`.

## 7. No sleeps as synchronization

### Hard rules

- Never use `thread::sleep`, `tokio::time::sleep`, or any timer as a synchronization or assertion barrier — it's flaky and slow. Wait on a real condition: a channel/`oneshot`, a `Notify`, an `AtomicBool` spin with a deadline, or a synchronous fake that records the call.
- Inject a clock (e.g. `tokio::time::pause`/`advance`, or a trait-based clock) instead of waiting for wall-clock time.

### Review questions

- Could this test flake because it sleeps for timing or talks to a real service?
- Is timing controlled by an injected/paused clock rather than the wall clock?

## 8. Isolation & seams

### Hard rules

- Tests don't depend on the network or live services. Fake at a trait the consumer owns, not a concrete external client.
- Don't add a `pub` method or field to production code solely so a test can observe it. Observe through a fake, a `#[cfg(test)]` hook, or by testing the public behavior.
- Use a `tempfile::TempDir` for scratch files; clean up via `Drop`/scope, not manual deletion that a panic can skip.

## 9. What makes missing tests blocking

Usually blocking:
- bug fix with no regression test
- new branch / error path with only happy-path coverage
- concurrency/async change with no test that exercises the new path
- behavior change on a critical path with no meaningful assertion

Usually suggestion:
- refactor with preserved behavior but no added tests
- weak assertions (`assert!(result.is_ok())`) where the value/variant should be checked
- copy-paste tests that should be a parameterized table
- a public API without a doctest

Usually nit:
- assert message wording, `assert_eq!` argument order
- test/case naming, helper extraction

## 10. Review wording

Don't say only "missing tests". Say: what behavior is unproven, why it matters, and what test would close the gap.
