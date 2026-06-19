# Severity Rubric (Rust)

Use this rubric to classify findings consistently. Rust's compiler already rules out whole bug classes (data races, use-after-free, null derefs in safe code), so blocking findings concentrate on what the compiler *can't* catch: reachable panics, `unsafe` soundness, deadlocks, logic/overflow errors, and swallowed failures.

## Blocking

Use `Blocking` when the issue should realistically stop the PR from merging.

Typical blocking cases:
- a reachable `panic!`/`unwrap`/`expect`/index/slice/division-by-zero that can fail on real input
- an `unsafe` block whose invariant isn't upheld or isn't documented, or a safe public fn that's unsound (UB reachable from safe code)
- a deadlock: lock-order inversion, double-lock of a non-reentrant `Mutex`, or a guard held across blocking work / `.await` (see `async.md`)
- blocking the async runtime (sync I/O, `block_on`, heavy CPU on a worker)
- a detached/leaked task or thread with no stop condition; child tasks orphaned on shutdown
- a swallowed error (`let _ =`, `.ok()`, ignored `Err`) on a path that can actually fail
- silent integer overflow or `as`-truncation that yields wrong results
- a `Drop` that panics, or a manual `unsafe impl Send/Sync` without justification
- a Clippy `deny`/compiler error/`forbid(unsafe_code)` violation
- missing regression test for a bug fix, or a behavioral change on a critical path with no meaningful coverage

Ask:
- Could this panic, deadlock, leak, or produce wrong results in production?
- Could a safe caller trigger UB?
- Does it violate a project lint posture (`deny`, `forbid`)?

## Suggestion

Use `Suggestion` for important improvements that should be fixed but don't block on their own.

Typical suggestion cases:
- non-idiomatic construct where idiomatic Rust is clearly better (explicit `match` → combinator, manual loop → iterator, `&Vec<T>`/`&String` params)
- a library exposing `anyhow::Error`/`Box<dyn Error>` where a concrete error enum belongs
- a missing common-trait derive on a public type (`Debug`, `Clone`, …), or `Deref` abused for inheritance
- single-syntax / consistency deviation from `consistency.md` (especially a file mixing two forms), or an unaddressed Clippy `warn`
- coarse locking that over-serializes; `tokio::sync::Mutex` where a dropped-before-await sync mutex would do
- an unbounded channel without justification; serialized independent awaits that should `join!`
- weak naming that isn't actively misleading; missing `# Errors`/`# Panics`/`# Safety` docs
- a `bool`/`Option` positional flag that should be a newtype or enum
- missing edge-case/error-path test on a non-critical path; copy-paste tests that should be parameterized

Ask:
- Does this make the code meaningfully harder to read, evolve, or use correctly?
- Is it a strong idiom/consistency default rather than a hard rule?

## Nit

Use `Nit` for low-impact polish.

Typical nit cases:
- error `Display` casing/punctuation
- `assert_eq!` argument order or message wording
- small rename, simplifiable expression, `format!` arg inlining
- doc-comment phrasing
- a guard/`drop` that could move a few lines for readability

Never raise a `rustfmt`-owned formatting issue as a per-line nit — the single finding is "run `cargo fmt`". Never restate a Clippy lint line-by-line — cite the lint once.

## Confidence

Every finding includes confidence:
- `high`: clear violation, bug, or soundness hole
- `medium`: likely issue, but local context may justify it
- `low`: speculative; raise carefully and explain the uncertainty

## Preference vs rule

Say explicitly when something is a preference or strong default rather than a hard rule.

Good: "Suggestion — not a hard rule, but this fights the combinator default in `consistency.md`; Clippy would flag it as `manual_map`."

Bad: presenting an idiom or consistency preference as if it were a soundness bug.
