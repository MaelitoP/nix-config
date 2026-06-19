# Async & Tokio Review Rules

Async Rust adds a concurrency dimension the borrow checker does *not* fully police: the runtime, blocking, cancellation, and task lifetimes are the reviewer's job. This lens pairs with `correctness-concurrency.md`. Grounded in the Tokio docs, *Rust for Rustaceans* (async chapter), and the async working group's guidance. Most rules are runtime-agnostic; Tokio is named where it's the de-facto target.

## 1. Don't block the executor

### Hard rules

- Never call a blocking operation inside an `async fn` on a runtime worker thread: synchronous file/network I/O, `std::thread::sleep`, a long CPU loop, `Mutex` contention on a sync lock, or `reqwest::blocking`. It stalls every task sharing that worker.
- Offload blocking/CPU work: `tokio::task::spawn_blocking(...)` for blocking I/O, a dedicated thread pool (`rayon`) for CPU-bound work. Use async-native I/O (`tokio::fs`, `tokio::net`) for I/O.
- Never call `Runtime::block_on` (or `futures::executor::block_on`) from inside an async task — it can deadlock the runtime.

### Review questions

- Does any `.await`-bearing function call a synchronous blocking API?
- Is there a CPU-heavy loop between `.await` points that should be `spawn_blocking`?

## 2. Locks across `.await`

### Hard rules

- Never hold a `std::sync::Mutex`/`RwLock` guard across an `.await`. The guard isn't `Send`, the future may move threads, and it can deadlock or fail to compile in a `Send` task. (Clippy `await_holding_lock`.)
- If you must hold a lock across `.await`, use `tokio::sync::Mutex` — but prefer to **restructure so the lock is dropped before awaiting**: compute under the lock, release, then await.
  ```rust
  // Avoid: guard lives across .await
  let mut g = state.lock().unwrap();
  g.value = fetch().await;            // holds std Mutex across await — wrong

  // Prefer: drop the guard first
  let v = fetch().await;
  state.lock().unwrap().value = v;    // short critical section, no await inside
  ```
- For shared state, a sync `std::sync::Mutex` with a short non-await critical section is usually better than `tokio::sync::Mutex`; reach for the async mutex only when the critical section genuinely must await.

## 3. Cancellation safety

### Hard rules

- A future can be dropped at any `.await` (timeout, `select!` losing a branch, the task being aborted). State mutated before that point but not committed can be lost or left half-done.
- Branches of `tokio::select!` must be **cancellation-safe**: dropping a not-yet-ready branch must not lose data. Reading from a channel with `recv()` is cancel-safe; a hand-rolled future that took an item out of a buffer before awaiting may not be. Check each branch.
- Don't hold a half-completed transaction/partial write across an `.await` that a timeout or `select!` can cancel without a way to roll back.

### Review questions

- If this future is dropped at this `.await`, is any state left inconsistent?
- Are all `select!` branches cancellation-safe, or does one lose an item when not chosen?

## 4. Task lifetimes & leaks

### Hard rules

- `tokio::spawn` returns a `JoinHandle`; a detached spawn with no join and no cancellation is the async analogue of a goroutine leak. Know where every task stops. (Cf. the Go rule: "before you launch it, know when it stops.")
- Dropping a `JoinHandle` detaches the task (it keeps running); aborting requires `handle.abort()` or a `CancellationToken`. Decide which you want.
- A task that loops on a channel/`select!` must have a shutdown path (closed channel, `CancellationToken`, shutdown signal) — otherwise it lives until the runtime ends.
- Spawned task closures are `'static` and `Send`; flag captured references forced into `Arc`/clones just to satisfy that — sometimes the work shouldn't be a separate task.

### Review questions

- Where does this spawned task exit? If "when the process dies", it's a leak under churn.
- On shutdown / parent error, are child tasks cancelled or awaited, or orphaned?

## 5. Channels & backpressure

### Strong defaults

- Pick the channel deliberately: `mpsc` (bounded for backpressure, unbounded risks unbounded memory), `oneshot` (single response), `broadcast` (fan-out, lagging receivers drop), `watch` (latest value).
- An unbounded channel under a fast producer / slow consumer is a memory leak in disguise — justify any unbounded channel.
- The sender closing is signaled by all senders dropping; a receiver loop should exit when `recv()` returns `None`/`Err(Closed)`. Don't loop forever ignoring the closed signal.

## 6. Futures discipline

### Hard rules

- A `Future` does nothing until polled — an `async fn` call you don't `.await` (and don't spawn) is dead code. Clippy/compiler flags an unused future; treat it as blocking.
- Don't `.await` futures sequentially when they're independent — use `tokio::join!`/`try_join!` for concurrency, or `FuturesUnordered`/`JoinSet` for a dynamic set.
- Pin and self-referential futures: flag manual `Pin`/`unsafe` poll implementations for the same scrutiny as any `unsafe` (see `correctness-concurrency.md`).

### Review questions

- Is an `async fn` called without `.await`/spawn (silently doing nothing)?
- Are independent awaits serialized where `join!` would run them concurrently?

## 7. What makes an async finding blocking

Usually blocking:
- a blocking call (sync I/O, `thread::sleep`, heavy CPU, `block_on`) on a runtime worker
- a `std::sync` lock guard held across `.await` (deadlock / `Send` break)
- a non-cancellation-safe `select!` branch that loses data
- a detached/leaked task with no stop condition, or a child task orphaned on shutdown
- an unawaited future that was supposed to run

Usually suggestion:
- `tokio::sync::Mutex` where a dropped-before-await `std::sync::Mutex` would do
- an unbounded channel without a justified reason
- serialized independent awaits that should `join!`

Usually nit:
- channel type choice that works but isn't the clearest fit
- a `spawn` that could be a `join!` for two known tasks
