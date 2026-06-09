# Severity Rubric (Go)

Use this rubric to classify findings consistently.

## Blocking

Use `Blocking` when the issue should realistically stop the PR from merging.

Typical blocking cases:
- data race or unsynchronized access to shared mutable state
- goroutine leak or resource leak (unclosed body/file/rows, leaked timer)
- swallowed error on a path that can actually fail
- dropped `context` cancellation/deadline on an outbound call, or a leaked `cancel`
- nil-map write, send on closed/nil channel, or typed-nil-as-error trap reachable in normal flow
- `go vet` failure or a file that isn't `gofmt`-clean
- panic used for ordinary error flow, or an unguarded panic in a request-scoped goroutine
- missing regression test for a bug fix, or a behavioral change on a critical path with no meaningful coverage

Ask:
- Could this cause wrong behavior, a crash, or data corruption in production?
- Could this leak goroutines/connections under load?
- Does it violate the language's safety rules or fail `go vet`?

## Suggestion

Use `Suggestion` for important improvements that should be fixed but don't block on their own.

Typical suggestion cases:
- non-idiomatic construct where idiomatic Go is clearly better
- interface defined at the producer, or created with a single implementation "just in case"
- single-syntax / consistency deviation from `consistency.md` (especially a file mixing two forms)
- error wrapped with `%v` where `%w` would serve callers, or missing useful context
- weak naming that isn't actively misleading
- missing edge-case/error-path test on a non-critical path
- `defer` in a loop, over-nesting that hurts line-of-sight

Ask:
- Does this make the code meaningfully harder to read, evolve, or use correctly?
- Is it a strong idiom/consistency default rather than a hard rule?

## Nit

Use `Nit` for low-impact polish.

Typical nit cases:
- error string casing/punctuation
- `got/want` ordering or test message wording
- small rename, simplifiable expression
- doc-comment phrasing
- moving a `defer` closer to its acquire

Never raise a `gofmt`-owned formatting issue as a per-line nit — the single finding is "run gofmt".

## Confidence

Every finding includes confidence:
- `high`: clear violation or bug
- `medium`: likely issue, but local context may justify it
- `low`: speculative; raise carefully and explain the uncertainty

## Preference vs rule

Say explicitly when something is a preference or strong default rather than a hard rule.

Good: "Suggestion — not a hard rule, but this fights the nil-slice default in `consistency.md`; the file uses both forms."

Bad: presenting an idiom or consistency preference as if it were a correctness bug.
