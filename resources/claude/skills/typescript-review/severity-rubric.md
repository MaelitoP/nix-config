# Severity Rubric (TypeScript)

Use this rubric to classify findings consistently. TypeScript's types are erased at runtime and unsound by design in places, so blocking findings concentrate on what passes `tsc` and still breaks: unverified claims about external data, assertions over values that can be absent, nullish and truthiness confusion, floating or mishandled promises, races across an `await`, swallowed errors, and JavaScript runtime traps.

## Blocking

Use `Blocking` when the issue should realistically stop the PR from merging.

Typical blocking cases:
- external data (`JSON.parse`, `response.json()`, env, storage, queue message, DB row) asserted into a domain type instead of parsed
- `any` leaking through an exported signature, a return-only generic, or `as` / `!` / `as unknown as` over a value that can really be absent or of another type
- a union member added while a `switch` over it silently falls through (no exhaustiveness check)
- `||` or a truthiness check that mishandles a valid `0` / `""` / `false`, producing wrong results
- a floating promise; an `async` callback handed to `forEach`, an event emitter, or a timer; a promise used as a boolean
- `return promise` inside a `try` whose `catch` was meant to handle the failure; eagerly started promises leaving a rejection unhandled
- a swallowed error (empty `catch`, `.catch(() => {})`), a lost cause, a non-`Error` thrown, or a fallback indistinguishable from real data, on a path that can fail
- check-then-act across an `await`, per-request data in module-level state, or a stale response overwriting a newer one
- unbounded `Promise.all` fan-out, an outbound call with no timeout on a request path, or a leaked listener / timer / handle
- synchronous I/O, heavy CPU, or a ReDoS-prone regex on the event loop
- default `sort()` on numbers, in-place mutation of a caller's data, `Date` logic that is wrong outside the author's time zone, float arithmetic for money, a lost `this`
- `@ts-ignore` / `@ts-nocheck` / `eslint-disable`, or a loosened `tsconfig.json` or lint config, hiding a real error
- a `tsc` error, a typed-lint error that is a real bug, or an unformatted file
- a missing regression test for a bug fix (or a test that passes with the fix reverted), a fixed-time sleep as a synchronization barrier, or a behavioral change on a critical path with no meaningful coverage

Ask:
- Could this produce wrong results, crash, leak, race, hang, or stall the loop in production?
- Is a claim made to the type checker that nothing verifies at runtime?
- Does it violate a gate the build enforces (`tsc`, the linter, the formatter check)?

## Suggestion

Use `Suggestion` for important improvements that should be fixed but don't block on their own.

Typical suggestion cases:
- modelling: an optional-field bag or boolean flags where a discriminated union fits; `string` where a literal union or brand belongs; `null` and `undefined` mixed for one meaning
- typing gaps: a missing return type on an exported function; a type parameter that appears once; type-level complexity a plain union would replace; duplicated shapes that should be derived; missing `readonly` on inputs
- an `as` or `!` that is safe today but replaceable by narrowing, a guard, or `satisfies`
- error design: an expected failure hidden from the signature; errors distinguished by message parsing; throw and result styles mixed for the same kind of failure
- API shape: positional boolean flags; a class that should be a function; a module-level singleton that should be injected; a default export; an over-wide export surface; a barrel file in application code; a third-party type leaking across a module boundary
- single-syntax / consistency deviation from `consistency.md` (especially a file mixing two forms), a new `enum`, or an unaddressed lint warning
- sequential awaits that could run concurrently; an async API with no `AbortSignal`
- weak naming that isn't actively misleading; a `utils` / `helpers` / `types` junk-drawer file; missing TSDoc on exported API
- tests: weak assertions; copy-paste tests that should be `it.each`; a module mock where an injected fake would do; an `as any` fixture; no type-level test for an exported generic; a missing edge-case test on a non-critical path

Ask:
- Does this make the code meaningfully harder to read, evolve, or use correctly?
- Is it a strong idiom/consistency default rather than a hard rule?

## Nit

Use `Nit` for low-impact polish.

Typical nit cases:
- error message wording
- test naming, assertion phrasing
- a small rename, an inferable annotation, a simplifiable expression
- TSDoc phrasing
- a type alias or type parameter name

Never raise a formatter-owned formatting issue as a per-line nit — the single finding is "run the formatter". Never restate a `tsc` or lint finding line by line — cite the error or rule code once.

## Calibrate to the project

- Read `tsconfig.json` and the lint config before grading. A missing index-access guard is a correctness finding when `noUncheckedIndexedAccess` is off and a compile error when it is on.
- Where `consistency.md` marks a choice *contested*, the project's configured rule decides; grade against it, not against this document's default.
- A PR that weakens a gate (turns off a strict flag, disables a lint rule, adds a blanket `eslint-disable`) is graded on what the gate was catching.

## Confidence

Every finding includes confidence:
- `high`: clear violation, bug, or contract break
- `medium`: likely issue, but local context may justify it
- `low`: speculative; raise carefully and explain the uncertainty

## Preference vs rule

Say explicitly when something is a preference or strong default rather than a hard rule.

Good: "Suggestion — not a hard rule, but this `type` alias for an object shape deviates from the `interface` default the repo's `consistent-type-definitions` rule enforces."

Bad: presenting an idiom or consistency preference as if it were a correctness bug.
