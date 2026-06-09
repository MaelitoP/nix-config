# Go Testing Review Rules

Grounded in the standard library's own test style, *Go Code Review Comments* ("useful test failures"), and the Google Go Style Guide.

## 1. General expectations

Tests should prove behavior, not restate implementation. A review asks:
- what behavior changed?
- what branch, invariant, or error path changed?
- what breaks if this is wrong?
- do the tests prove the new behavior, including the failure paths?

## 2. Table-driven tests

### Strong defaults

- Prefer table-driven tests for any function with multiple input/output cases. This is the idiomatic Go pattern and keeps cases uniform.
- Each case is a struct in a slice; give cases a `name` field and run them with `t.Run(tt.name, ...)` so failures are addressable and `-run` can target one.
- Mark the test func parallel and, where safe, each subtest `t.Parallel()`.

```go
tests := []struct {
    name string
    in   string
    want int
}{
    {name: "empty", in: "", want: 0},
    {name: "ascii", in: "go", want: 2},
}
for _, tt := range tests {
    t.Run(tt.name, func(t *testing.T) {
        got := Len(tt.in)
        if got != tt.want {
            t.Errorf("Len(%q) = %d, want %d", tt.in, got, tt.want)
        }
    })
}
```

### Review questions

- Is this a pile of near-duplicate test functions that should be one table?
- Do subtests have stable, descriptive names?

## 3. Useful failure messages

### Hard rules

- A failure message must show input, what you got, and what you wanted: `t.Errorf("Foo(%q) = %v, want %v", in, got, want)`.
- Use the `got, want` ordering convention consistently.
- Don't assert with a bare `t.Fail()` or a message that omits the values.

## 4. Assertions: stdlib vs testify

### Strong defaults

- Plain `testing` with `if got != want { t.Errorf(...) }` is the default and always acceptable. For structs/slices use `reflect.DeepEqual` or `google/go-cmp` (prefer `cmp.Diff` — its output is far more useful).
- If the codebase already uses `testify`, be consistent with it; do not mix `testify/assert` and hand-written checks within the same package without reason.
- Use `require` (stops the test) for preconditions whose failure makes the rest meaningless; `assert` (continues) for independent checks. Don't use `assert` where a nil-deref will follow.

## 5. Helpers & cleanup

### Hard rules

- Test helpers that call `t.Fatal`/`t.Error` must call `t.Helper()` so failures point at the caller.
- Use `t.Cleanup(...)` (or `defer`) to release resources; use `t.TempDir()` for scratch files.

## 6. Concurrency in tests

### Hard rules

- Never call `t.Fatal`/`FailNow` from a goroutine other than the test's own — it doesn't stop the test correctly. Send the failure back to the test goroutine (channel/error) and assert there. `t.Error` is goroutine-safe but `Fatal` is not.
- Race-sensitive changes must be exercised with `go test -race`. Flag concurrency changes that ship without it.

## 7. Isolation

### Hard rules

- Tests must not depend on the network or live services. Stub at an interface the consumer defines (see `idioms.md`), not a concrete type.
- No reliance on wall-clock sleeps for synchronization; inject a clock or use channels/`sync` primitives.

### Review questions

- Could this test flake because it talks to a real service or sleeps for timing?
- Is the seam an interface owned by the consumer, or a concrete dependency that's hard to fake?

## 8. Examples & docs

- For exported packages, runnable `Example` functions double as documentation and are verified by `go test`. Encourage them for non-trivial new public APIs.

## 9. What makes missing tests blocking

Usually blocking:
- bug fix with no regression test
- new branch / error path with only happy-path coverage
- concurrency change without `-race` coverage
- behavior change on a critical path with no meaningful assertion

Usually suggestion:
- refactor with preserved behavior but no added tests
- weak assertions where broad coverage already exists
- missing edge case on low-risk code
- non-table duplicate tests that should be consolidated

Usually nit:
- `got/want` ordering, message wording
- subtest naming, helper extraction

## 10. Review wording

Don't say only "missing tests". Say: what behavior is unproven, why it matters, and what test would close the gap.
