# Java Testing Review Rules

Grounded in JUnit 5 (Jupiter) conventions, AssertJ/Hamcrest assertions, Mockito's "mock the seams you own" guidance, and *Effective Java* Item 5 (dependency injection makes code testable). Tests prove behavior and catch regressions — they don't pad volume.

## 1. General expectations

A review asks:
- what behavior changed?
- what branch, invariant, or exception path changed?
- what breaks if this is wrong?
- do the tests prove the new behavior, including the failure paths?

## 2. Structure & framework

### Strong defaults

- JUnit 5 (Jupiter): `@Test`, `@BeforeEach`/`@AfterEach`, `@Nested` for grouping related cases, `@DisplayName` for readable names. Don't mix JUnit 4 (`org.junit.Test`, `@Before`) into a Jupiter file.
- One assertion library per module, used consistently. AssertJ (`assertThat(x).isEqualTo(...)`, `.containsExactly(...)`, `.hasMessageContaining(...)`) reads best and gives rich failure messages; Hamcrest `assertThat(x, is(...))` is acceptable if it's the house style. Don't mix AssertJ and raw JUnit `assertEquals` and Hamcrest in the same file.
- Test names state behavior, not mechanics: `returnsEmptyWhenInputBlank`, not `test1`/`testGetName`.

### Review questions

- Does the file mix JUnit 4 and 5, or mix assertion libraries?
- Is a behavior reachable only through the public API tested only via reflection/internals?

## 3. Parameterized cases over copy-paste

### Strong defaults

- Multiple input/output cases belong in a `@ParameterizedTest` (`@ValueSource`, `@CsvSource`, `@MethodSource`, `@EnumSource`) — not copy-pasted near-identical `@Test` methods. Near-duplicate test bodies are a finding.
- Use `@EnumSource` to cover every enum constant; `@MethodSource` for structured cases.

```java
@ParameterizedTest
@CsvSource({"'', 0", "go, 2", "héllo, 5"})
void countsChars(String input, int want) {
    assertThat(charLen(input)).as("charLen(%s)", input).isEqualTo(want);
}
```

### Review questions

- Is this a pile of near-duplicate `@Test` methods that should be one `@ParameterizedTest`?

## 4. Useful assertions & failure messages

### Hard rules

- Assert the value/content, not just a boolean: `assertThat(result).contains(expected)`, not `assertTrue(result.contains(expected))` (which prints nothing useful on failure). `assertThat(opt).contains(v)`, not `assertTrue(opt.isPresent())`.
- Add an `.as(...)`/description when the assertion alone won't identify the case.
- Use `assertThatThrownBy(...)` / `assertThrows(...)` and assert the exception **type and message/cause**, not merely that something threw. A bare `assertThrows(Exception.class, ...)` can pass for the wrong exception.
- No assertion that cannot fail (asserting a literal against itself, or re-asserting what a mock was just told to return).

## 5. Exception & edge paths

### Hard rules

- Test the exception paths, not just the happy path. Assert the variant/message (`assertThatThrownBy(...).isInstanceOf(IllegalArgumentException.class).hasMessageContaining("id")`).
- A bug fix needs a regression test that fails before the fix.
- Cover the boundaries: empty, null, single-element, max — not just the typical case.

## 6. Mocking at the seams you own

### Hard rules

- Mock at an interface/seam the **consumer owns** (a repository, a gateway, a clock) — not a concrete third-party client or a value type. Mocking a `record`/value object or a type you don't control is a smell; construct the real value instead.
- Don't `mock`/`when(...)` something and then assert it returns what you stubbed — that tests the mock, not the code.
- Prefer constructor injection (*Effective Java* Item 5) so the test passes a fake/stub in directly, with no container, no reflection, and no field-injection hacks.
- Don't add a `public`/`protected` accessor to production code solely so a test can observe internal state — observe through a fake, the public behavior, or a package-private test hook.

### Review questions

- Is a value type or an unowned concrete class being mocked where a real instance would do?
- Was a production member widened just for the test to peek at it?

## 7. No sleeps as synchronization

### Hard rules

- **Never** use `Thread.sleep`, `TimeUnit.sleep`, or any timer as a synchronization or assertion barrier — it's flaky and slow, and against a memory-model race it doesn't even establish visibility. Wait on a real condition:
  - a `CountDownLatch`/`CompletableFuture`/`BlockingQueue` the code under test signals,
  - a polling helper with a deadline (`Awaitility`: `await().atMost(2, SECONDS).until(() -> ...)`), or
  - a `Semaphore`/`Phaser` that records the awaited event.
- Inject a `Clock` (`Clock.fixed`) instead of sleeping for time-dependent logic; advance a fake clock rather than waiting on the wall clock.
- For deterministic concurrency tests, drive worker threads with a latch so they all start together; assert after `awaitTermination` / `future.get()`, not after a sleep.

### Review questions

- Could this test flake because it sleeps for timing or talks to a real service/clock?
- Is timing controlled by an injected `Clock` or an `Awaitility` deadline rather than `Thread.sleep`?

## 8. Concurrency tests & isolation

### Hard rules

- An assertion that fails inside a spawned thread/executor is swallowed — the test thread never sees the `AssertionError` and the test passes green. Collect results/exceptions back on the main thread (via `Future.get()`, a `BlockingQueue`, or an `AtomicReference`) and assert there.
- Tests don't depend on the network, a real database, or wall-clock time. Fake at an owned seam; use Testcontainers / an in-memory fake for integration, not a shared live service.
- Use JUnit's `@TempDir` for scratch files; cleanup happens via the framework, not manual deletion a failure can skip.

## 9. What makes missing tests blocking

Usually blocking:
- a bug fix with no regression test
- a new branch / exception path with only happy-path coverage
- a concurrency change with no test exercising the new path (and no swallowed-assertion-in-thread trap)
- a behavior change on a critical path with no meaningful assertion

Usually suggestion:
- a refactor with preserved behavior but no added tests
- weak assertions (`assertTrue(opt.isPresent())`) where the value/variant should be checked
- copy-paste `@Test` methods that should be a `@ParameterizedTest`
- mocking a value type or an unowned class

Usually nit:
- assertion description wording, AssertJ vs `assertEquals` argument order
- test/case naming, helper extraction

## 10. Review wording

Don't say only "missing tests". Say: what behavior is unproven, why it matters, and what test would close the gap.
