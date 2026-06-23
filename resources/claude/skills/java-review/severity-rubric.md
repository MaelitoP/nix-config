# Severity Rubric (Java)

Use this rubric to classify findings consistently. Java gives you no compile-time race or null safety, so blocking findings concentrate on what slips past the compiler: reachable `NullPointerException`s, resource leaks, broken equality/ordering contracts, swallowed exceptions, numeric traps, and data races.

## Blocking

Use `Blocking` when the issue should realistically stop the PR from merging.

Typical blocking cases:
- a reachable `NullPointerException` (unchecked null return, null-unboxing, `Optional.get()` without a check) on real input
- a resource leak: an `AutoCloseable`/`ExecutorService` not closed on an exception path
- a swallowed/discarded exception (empty `catch`, lost cause, swallowed `InterruptedException`) on a path that can fail
- `equals` without `hashCode` (or vice versa), a broken `equals`/`compareTo` contract, or a mutable object used as a hash key
- silent integer overflow, `int`-division truncation, narrowing-cast, `==` on `String`/boxed, or `double` for money — producing wrong results
- a missing defensive copy that lets a caller mutate internal state (Item 50)
- a data race: shared mutable state without `synchronized`/`volatile`/atomic; a non-atomic compound action on shared state; a deadlock (lock-order inversion, lock held across I/O)
- a leaked/never-shut-down executor; a task/thread with no stop condition; pooling virtual threads or CPU-bound work on them at scale
- a compile error, or an Error Prone `ERROR`-level pattern / SpotBugs high-priority bug
- a missing regression test for a bug fix, or a behavioral change on a critical path with no meaningful coverage

Ask:
- Could this NPE, leak, deadlock, race, or produce wrong results in production?
- Does it break a value/ordering contract or a documented project rule?
- Does it violate a tool gate the build enforces (Error Prone error, SpotBugs, failing format check)?

## Suggestion

Use `Suggestion` for important improvements that should be fixed but don't block on their own.

Typical suggestion cases:
- non-idiomatic construct where modern idiomatic Java is clearly better (instanceof-and-cast → `instanceof` pattern; fall-through `switch` statement → `switch` expression; hand-written value class → `record`; `null` return → empty collection / `Optional` return type)
- a checked exception the caller can't act on (Item 71), or a bespoke exception where a standard one fits (Item 72)
- `Optional` used as a field/parameter; a missing `@Override`; a raw generic type; a broad `catch (Exception)`
- single-syntax / consistency deviation from `consistency.md` (especially a file mixing two forms), or an unaddressed PMD/Error Prone warning
- coarse locking that over-serializes; hand-rolled `wait`/`notify` where a `java.util.concurrent` utility fits
- weak naming that isn't actively misleading; a `Util`/`Helper` junk-drawer class; missing Javadoc / thread-safety documentation on public API
- a mutable field that should be `final`/immutable; a constructor with many params that should be a builder
- missing edge-case/exception-path test on a non-critical path; copy-paste tests that should be parameterized; mocking a value type

Ask:
- Does this make the code meaningfully harder to read, evolve, or use correctly?
- Is it a strong idiom/consistency default rather than a hard rule?

## Nit

Use `Nit` for low-impact polish.

Typical nit cases:
- exception message wording
- AssertJ vs `assertEquals` argument order, assertion description wording
- a small rename, a simplifiable expression, `var` where it would remove redundancy
- Javadoc phrasing
- a lock scope or guard that could move a few lines for readability

Never raise a formatter-owned formatting issue as a per-line nit — the single finding is "run the formatter" (`spotless:apply` / `spotlessApply`). Never restate an Error Prone / SpotBugs / PMD finding line-by-line — cite the check once.

## Confidence

Every finding includes confidence:
- `high`: clear violation, bug, or contract break
- `medium`: likely issue, but local context may justify it
- `low`: speculative; raise carefully and explain the uncertainty

## Preference vs rule

Say explicitly when something is a preference or strong default rather than a hard rule.

Good: "Suggestion — not a hard rule, but this fights the `switch`-expression default in `consistency.md`, and the file already uses the arrow form elsewhere."

Bad: presenting an idiom or consistency preference as if it were a correctness bug.
