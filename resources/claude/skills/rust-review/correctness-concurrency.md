# Correctness & Concurrency Review Rules

The highest-priority lens. A correctness or safety bug outranks every style concern. Rust's type system prevents data races at compile time, so the blocking concerns shift toward **reachable panics, `unsafe` soundness, deadlocks, swallowed errors, and overflow**. Grounded in *Effective Rust*, *Programming Rust*, the Rustonomicon, and the Clippy correctness lints. (Async-specific correctness lives in `async.md`.)

## 1. Panics on reachable paths

### Hard rules

- Don't `panic!`/`unwrap`/`expect`/`unreachable!`/`todo!` on a value that can be `None`/`Err`/out-of-range from real input. A library that panics crashes its caller. (*Effective Rust* Item 18: don't panic.)
- Indexing (`v[i]`, `s[a..b]`) panics on out-of-bounds — use `.get(i)`/`.get(a..b)` when the index isn't proven in range.
- Integer division and remainder by a possibly-zero divisor panics — guard or use `checked_div`.
- `unwrap`/`expect` are acceptable for genuinely-unreachable invariants (prefer `expect("why it can't fail")` so the reason is recorded) and freely in tests.

### Review questions

- Can this `unwrap`/index/division receive input that makes it panic in production?
- Is there a `# Panics` doc section for any public function that can panic?

## 2. Arithmetic overflow

### Hard rules

- Integer overflow panics in debug but **silently wraps in release** by default. Don't rely on the debug panic for correctness.
- Choose the behavior deliberately: `checked_add` (→ `Option`), `saturating_add`, `wrapping_add`, or `overflowing_add`. Casting with `as` truncates silently — prefer `TryFrom`/`try_into()` when the value might not fit.

### Review questions

- Does this arithmetic on untrusted/large values need `checked_`/`saturating_`?
- Does an `as` cast silently truncate or change sign?

## 3. Error-handling correctness

### Hard rules

- Never silently discard an error. `let _ = fallible();`, `.ok()` to drop an `Err`, or `if let Ok(x) = ...` that ignores the `Err` are findings unless the discard is deliberate *and* commented as safe.
- Check/propagate the error before using other values — after an `Err`, the rest of the computation is usually invalid.
- Convert error types via `?` + `From`/`#[from]`; don't compare or match on error *strings*.
- Don't both return an error and log it at the same layer (double reporting); handle it or propagate it, not both.
- `Result` is `#[must_use]` — an unused `Result` is a Clippy finding; don't suppress it without handling.

### Review questions

- Is a `Result`/`Option` dropped on a path that can actually fail?
- Does `?` lose context a caller would need? (Add `.context`/a variant, don't swallow.)

## 4. `Send` / `Sync` and shared state

### Hard rules

- Shared mutable state across threads must be synchronized: `Arc<Mutex<T>>`/`Arc<RwLock<T>>`, atomics, or message passing. The compiler enforces `Send`/`Sync`, but review the *design*: is the locking granularity right, or is the `Mutex` so coarse it serializes everything?
- A manual `unsafe impl Send`/`unsafe impl Sync` is a blocking-level review item — it asserts thread-safety the compiler couldn't prove. Demand a `// SAFETY:` justification.
- Don't share `Rc`/`RefCell` across threads (the compiler stops you, but flag designs that reach for `unsafe` to do it anyway).

### Review questions

- Is the critical section as small as it can be, or does it hold the lock across unrelated work?
- Is shared state actually shared, or could it be owned by one thread and messaged?

## 5. Deadlocks & locking discipline

### Hard rules

- Establish a consistent lock acquisition order; acquiring two locks in different orders on different paths is a deadlock waiting to happen.
- Don't re-acquire a non-reentrant `Mutex` you already hold (`std::sync::Mutex` is not reentrant — double lock deadlocks).
- Drop a guard before doing slow/blocking work or calling back into code that may lock again. Hold the guard for the shortest scope; use an explicit `drop(guard)` or a `{ }` block.
- (Async: never hold a `std::sync::Mutex` guard across `.await` — see `async.md`.)

### Review questions

- Could two code paths lock A→B and B→A?
- Is a lock held across a callback, channel send, or I/O call that could block?

## 6. `unsafe` and soundness

### Hard rules

- Every `unsafe` block/`fn` must uphold its invariants and carry a `// SAFETY:` comment proving them (the counterpart to the `# Safety` doc section). An undocumented `unsafe` block is a finding. (*Effective Rust* Item 16: avoid unsafe; the Rustonomicon for the rules.)
- A safe public function must be *sound*: no input may cause UB. If callers must uphold a precondition, the function must be `unsafe fn` with a documented contract.
- Watch for the classic UB sources: aliasing `&mut` (e.g. via raw pointers), reading uninitialized memory, `transmute` between incompatible layouts, extending a lifetime, breaking `Pin` guarantees, data races behind raw pointers.
- Prefer `#![forbid(unsafe_code)]` where the crate doesn't need `unsafe`; a new `unsafe` block in such a crate is blocking.

### Review questions

- Does this `unsafe` block actually uphold the invariant its comment claims?
- Could a safe caller pass input that triggers UB? Then the fn must be `unsafe` or validate.

## 7. Drop / RAII correctness

### Hard rules

- Destructors must not panic (`C-DTOR-FAIL`) — a panic during unwinding aborts the process.
- A `Drop` that may block needs a non-blocking alternative or explicit close method (`C-DTOR-BLOCK`).
- Don't rely on `Drop` running if you `mem::forget` or leak via a reference cycle (`Rc` cycles never drop). Flag `Rc<RefCell<...>>` graphs that can form cycles.

## 8. Slices, iterators & aliasing

### Strong defaults

- `chunks`/`windows`/`split_at` panic on zero or out-of-range arguments — validate.
- Mutating a collection while iterating it is a borrow error in safe Rust (good), but flag designs that collect indices then mutate, risking stale indices.
- Beware `iter().enumerate()` index reuse after a `retain`/`remove` shifts elements.

## 9. What makes a correctness finding blocking

Usually blocking:
- a reachable `panic!`/`unwrap`/`expect`/index/slice/division that can fail on real input
- an `unsafe` block with an unupheld or undocumented invariant, or a safe-but-unsound public fn (UB reachable)
- a deadlock (lock-order inversion, double-lock, guard held across blocking work)
- a swallowed error on a path that can actually fail
- silent overflow/`as`-truncation that produces wrong results
- a `Drop` that panics, or an `unsafe impl Send/Sync` without justification

Usually suggestion:
- coarse locking that over-serializes
- `unwrap` on a near-certain invariant that should be `expect("reason")`
- an `as` cast that should be `try_into()` for clarity even if currently in range

Usually nit:
- error `Display` casing/punctuation
- a guard that could drop a few lines earlier for readability
