# Python Testing Review Rules

Grounded in pytest conventions, *Effective Python*'s testing chapter, and the "mock the seams you own" discipline. Tests prove behavior and catch regressions — they don't pad volume.

## 1. General expectations

A review asks:
- what behavior changed?
- what branch, invariant, or exception path changed?
- what breaks if this is wrong?
- do the tests prove the new behavior, including the failure paths?

## 2. Structure & framework

### Strong defaults

- **pytest** is the default: `test_*` functions (not `unittest.TestCase` boilerplate unless that's the house style), fixtures for setup/teardown, plain `assert` (pytest rewrites it into a rich failure message). Don't mix a `unittest.TestCase` style and bare pytest functions in the same file.
- Use fixtures (`@pytest.fixture`) for shared setup; prefer function-scoped fixtures and explicit dependencies over module-level mutable state.
- Test names state behavior, not mechanics: `test_returns_empty_when_input_blank`, not `test_1`/`test_get`.

### Review questions

- Does the file mix `unittest` and pytest idioms?
- Is shared mutable fixture state casually carried between tests?

## 3. Parameterize over copy-paste

### Strong defaults

- Multiple input/output cases belong in `@pytest.mark.parametrize`, not copy-pasted near-identical test functions. Near-duplicate test bodies are a finding.

```python
@pytest.mark.parametrize(
    ("text", "want"),
    [("", 0), ("go", 2), ("héllo", 5)],
)
def test_char_len(text, want):
    assert char_len(text) == want
```

### Review questions

- Is this a pile of near-duplicate test functions that should be one parameterized test?

## 4. Useful assertions

### Hard rules

- Assert the value/content, not just truthiness: `assert result == expected` (pytest shows both sides), not `assert result` when you mean a specific value. `assert user.name == "Ada"`, not `assert user`.
- Assert exceptions with `pytest.raises` and check the **type and message**, not merely that something raised:
  ```python
  with pytest.raises(ValueError, match="id must be positive"):
      make_user(id=-1)
  ```
- No assertion that cannot fail (asserting a literal against itself, or re-asserting what a mock was just told to return).

## 5. Exception & edge paths

### Hard rules

- Test the exception paths, not just the happy path. Assert the type and message via `pytest.raises(..., match=...)`.
- A bug fix needs a regression test that fails before the fix.
- Cover boundaries: empty, `None`, single element, large/streamed input — not just the typical case.

## 6. Mocking at the seams you own

### Hard rules

- Mock/`monkeypatch` at a seam the **consumer owns** (a repository, a gateway, a clock, an HTTP client injected as a dependency) — not a value object and not deep internals you don't control. Mocking a dataclass/value type is a smell; construct the real value.
- Don't `Mock(return_value=...)` something and then assert it returns that value — that tests the mock, not the code.
- Prefer dependency injection (pass the collaborator as an argument) so the test passes a fake directly, rather than patching a module global. `monkeypatch.setattr` is the tool when you must patch; reach for it after DI, not instead of it.
- Don't add a public attribute/method to production code solely so a test can observe internal state — observe through a fake, the public behavior, or a narrow seam.

### Review questions

- Is a value type or an unowned concrete class being mocked where a real instance would do?
- Was a production member widened just for the test to peek at it?

## 7. No sleeps as synchronization

### Hard rules

- **Never** use `time.sleep` (or `asyncio.sleep`) as a synchronization or assertion barrier — it's flaky and slow, and against a memory-model/threading race it doesn't even establish ordering. Wait on a real condition:
  - a `threading.Event`/`Condition` the code under test signals,
  - a `queue.Queue.get(timeout=...)` / a `Future.result(timeout=...)`,
  - a polling helper with a deadline (e.g. assert-until-true with a timeout), or
  - an injected clock you advance, rather than wall-clock time.
- For time-dependent logic, inject a clock (a `now()` callable, `freezegun`, or `time-machine`) instead of sleeping.

### Review questions

- Could this test flake because it sleeps for timing or talks to a real service/clock?
- Is timing controlled by an injected clock or a deadline-bounded poll rather than `time.sleep`?

## 8. Async tests & isolation

### Hard rules

- Async tests use `pytest-asyncio` (`@pytest.mark.asyncio`) or `anyio`; the same async rules apply — no blocking calls on the loop, no swallowed `CancelledError`.
- An assertion that fails inside a spawned thread/executor is swallowed — the test thread never sees the `AssertionError`. Collect results/exceptions back on the main thread (via `Future.result()`, a `queue.Queue`, or a shared container) and assert there.
- Tests don't depend on the network, a real database, or wall-clock time. Fake at an owned seam; use `tmp_path` for scratch files (cleanup is automatic), not manual deletion a failure can skip.

## 9. What makes missing tests blocking

Usually blocking:
- a bug fix with no regression test
- a new branch / exception path with only happy-path coverage
- a concurrency/async change with no test exercising the new path (and no swallowed-assertion-in-thread trap)
- a behavior change on a critical path with no meaningful assertion

Usually suggestion:
- a refactor with preserved behavior but no added tests
- weak assertions (`assert result`) where the value should be checked
- copy-paste tests that should be parameterized
- mocking a value type or an unowned class

Usually nit:
- assertion/`match` wording, test naming
- fixture/helper extraction

## 10. Review wording

Don't say only "missing tests". Say: what behavior is unproven, why it matters, and what test would close the gap.
