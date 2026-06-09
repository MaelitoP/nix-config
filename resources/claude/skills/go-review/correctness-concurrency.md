# Correctness & Concurrency Review Rules

The highest-priority lens. A concurrency or correctness bug outranks every style concern. Grounded in *Effective Go*, the Go memory model, *Go Code Review Comments*, and Dave Cheney's *Practical Go*.

## 1. Goroutine lifetimes

### Hard rules

- Every goroutine must have a clear, knowable stop condition. *"Before you launch a goroutine, know when, and whether, it will stop."* (Cheney, Zen of Go)
- Do not start a goroutine without a way to wait for it or cancel it — pass a `context.Context`, use a `sync.WaitGroup`, or have it own a channel it closes.
- A library should not start goroutines on the caller's behalf without making the lifetime explicit. Leave concurrency to the caller where possible.

### Review questions

- Where does this goroutine exit? If the answer is "when the process dies", that is a leak.
- If the parent returns early (error path), does the goroutine still terminate?
- Is anything `range`-ing a channel that no one closes?

## 2. Data races and shared state

### Hard rules

- Shared mutable state accessed from multiple goroutines must be synchronized — `sync.Mutex`, `sync/atomic`, or confined to a single goroutine and communicated over a channel. *"Don't communicate by sharing memory; share memory by communicating."* (Pike)
- Do not copy a `sync.Mutex`, `sync.WaitGroup`, or any type embedding them (`go vet` catches many of these — treat as blocking).
- Maps are not safe for concurrent read/write. A concurrent write panics. Use a mutex or `sync.Map` where appropriate.
- Append to a shared slice is not safe under concurrency.

### Review questions

- Is this field read by one goroutine and written by another with no lock?
- Was the code tested with `go test -race`? Race-sensitive changes without `-race` coverage are suspect.
- Is a mutex passed or stored by value somewhere, silently copying it?

## 3. Channels

### Strong defaults

- The sender closes a channel, never the receiver. Closing from the receiver side, or closing twice, panics.
- Sending on a closed channel panics; sending on a nil channel blocks forever.
- Prefer `select` with a `ctx.Done()` case for any blocking send/receive that should be cancellable.
- Unbuffered channels synchronize; buffered channels decouple. Choose deliberately and justify a buffer size — a magic buffer size is a smell.

## 4. context.Context

### Hard rules

- `context.Context` is the first parameter, named `ctx`. Never store a `Context` in a struct field; pass it through the call chain.
- Do not pass `nil` as a `Context`; use `context.TODO()` if you genuinely don't have one yet.
- A `context.WithCancel`/`WithTimeout`/`WithDeadline` returns a `cancel` func that must be called (usually `defer cancel()`), even on the success path, to release resources.
- Propagate the incoming `ctx` to downstream calls (DB, HTTP, RPC). A fresh `context.Background()` mid-request drops cancellation and deadlines.

### Review questions

- Does this outbound call (HTTP, DB, gRPC) carry the request `ctx`?
- Is `cancel` leaked (created but never deferred/called)?
- Is `ctx.Value` being used to pass required parameters? That is a smell — values are for request-scoped metadata, not dependencies.

## 5. Error handling correctness

### Hard rules

- Never silently discard an error. If you ignore one, it must be a deliberate `_ =` with a comment explaining why it is safe.
- Check the error before using the other return values — a non-nil error usually means the other values are unusable.
- Use `errors.Is` for sentinel comparison and `errors.As` for typed extraction. Do not compare error strings.
- When you wrap, wrap with `%w` (`fmt.Errorf("doing X: %w", err)`) so callers can still `Is`/`As` through it. Wrap with `%v` only when you deliberately want to *opaque* the cause.
- Do not wrap and also return the original separately, and do not double-log: handle the error or return it, not both.

### Review questions

- Is an error from `defer f.Close()` being dropped on a writable file? On writes, a deferred close can hide a flush error — capture it.
- Does this `%w` chain expose an internal error type as part of the package's API contract by accident?
- Is the happy path indented under the error check instead of the error returning early? (See `consistency.md` — indent-error-flow.)

## 6. Resource leaks

### Hard rules

- Every `Open`/acquire has a matching `Close`/release, normally via `defer` immediately after the successful acquire.
- Always close `http.Response.Body` (and on the server, drain it) — leaking it leaks connections.
- `time.NewTimer`/`time.NewTicker` must be `Stop()`ped; a bare `time.After` in a loop leaks until it fires.
- `sql.Rows` must be closed; check `rows.Err()` after the loop.

### Review questions

- Is `defer` inside a loop accumulating until the function returns? Extract the loop body into a function so `defer` runs each iteration.
- Is a returned `io.ReadCloser` closed by the caller? Is that documented?

## 7. Nil traps

### Hard rules

- Writing to a nil map panics. A map must be made with `make` (or a literal) before writing; reading a nil map is fine.
- A nil slice is usable for `append`/`range`/`len` — prefer it over an empty slice literal (see `consistency.md`).
- A nil interface is not equal to an interface holding a nil pointer. Returning a typed nil pointer as an `error` makes `err != nil` true. Return a literal `nil` for the no-error case.

### Review questions

- Could this map be written to before it is initialized?
- Does any function return a concrete typed pointer as an `error` interface, risking the typed-nil trap?

## 8. Panics

### Hard rules

- Don't panic for ordinary errors. Use `error` returns. (*Go Code Review Comments* — "Don't panic".)
- `panic`/`recover` is for truly unrecoverable states or for crossing a package boundary that must not leak panics; `recover` only works in a deferred function in the same goroutine.
- A panic in a goroutine with no recover crashes the whole process — never let request-scoped goroutines panic unguarded.

## 9. What makes a correctness finding blocking

Usually blocking:
- a data race or unsynchronized shared write
- a goroutine or resource leak
- a swallowed error on a path that can actually fail
- dropped `context` cancellation on an outbound call
- nil-map write or send-on-closed-channel reachable in normal flow
- a `go vet` failure

Usually suggestion:
- missing `defer cancel()` where the context is short-lived anyway
- buffered channel with an unexplained size
- error wrapped with `%v` where `%w` would serve callers better

Usually nit:
- error string casing/punctuation
- a `defer` that could move closer to the acquire for readability
