# Async & Promise Review Rules

Promises add failure modes the type checker does not police on its own: a promise nobody awaits, a rejection nobody handles, work that runs in sequence by accident or in parallel without a bound, operations that cannot be cancelled, and one slow callback stalling everything. Typed linting catches several of these; the rest are the reviewer's job. This lens pairs with `correctness-concurrency.md`. Grounded in the typescript-eslint rule docs (`no-floating-promises`, `no-misused-promises`, `return-await`, `await-thenable`), Jake Archibald's posts on async functions and unhandled rejections, Nolan Lawson's "We have a problem with promises", MDN, and the Node.js docs ("Don't Block the Event Loop", events, process).

## 1. No floating promises

### Hard rules

- Every promise is awaited, returned, or explicitly handled. A call to an `async` function whose result is dropped runs detached: its rejection is unhandled (which crashes a Node process by default) and nothing waits for its effects. (`no-floating-promises`.)
- `void promise` silences the lint and nothing else; the rejection is still unhandled. A deliberate fire-and-forget attaches a `.catch` that reports the error, and has an owner that knows when it stops.
- An array of promises that is never passed to a combinator is a set of floating promises.

### Review questions

- Is there an `async` call here whose result is neither awaited nor returned?
- If this background work rejects, who finds out?

## 2. Promises where a synchronous value is expected

### Hard rules

- An `async` callback passed where the caller ignores the return value floats every promise it creates: `forEach(async …)`, an event listener, an `EventEmitter` handler, a `setTimeout` callback. The loop or emitter moves on before the work finishes and rejections go nowhere. (`no-misused-promises`.)
  ```ts
  // Wrong: returns before any save completes; failures are unhandled
  ids.forEach(async (id) => { await save(id); });

  // Right: sequential
  for (const id of ids) await save(id);
  // Right: concurrent
  await Promise.all(ids.map((id) => save(id)));
  ```
- A promise in a condition is always truthy: `if (isAllowed(user))` on an async function is a bug.
- No `new Promise(async (resolve, reject) => …)`: a throw inside the executor is lost. Never spread a promise into an object.
- Calling an `async` function without `await` inside `try` moves the rejection outside the `try`.

### Strong defaults

- In Node, an async event handler needs its own `try`/`catch` (or `captureRejections`); never an async `'error'` handler.

## 3. `await`, `return`, and `try`

### Hard rules

- Inside `try` / `catch` / `finally` (and a `using` scope), write `return await promise`. A bare `return promise` leaves the block before the promise settles, so the local `catch` never sees the rejection and `finally` runs early. (`return-await`; Archibald, "await vs return vs return await".)
  ```ts
  async function load(): Promise<Data> {
    try {
      return await fetchData();
    } catch (err) {
      throw new LoadError("load failed", { cause: err });
    }
  }
  ```
- Awaiting a non-thenable is usually a missing call or a wrong type. (`await-thenable`.)
- An `async` function with no `await` that doesn't return a promise is either missing an `await` or shouldn't be `async`. (`require-await`.)

### Strong defaults

- `async`/`await` over `.then` chains. Where `.then` remains: always return from the callback, and remember `then(onOk, onErr)` does not catch a throw from `onOk` (Lawson).
- A function that may throw synchronously before returning a promise gives callers two failure channels. Make it `async`, or wrap the call in `Promise.try`.

## 4. Sequential vs concurrent

### Hard rules

- Promises start eagerly. Starting several and then awaiting them one at a time leaves the later ones unobserved: if an early `await` throws or the loop exits, a later rejection is unhandled. Hand them to a combinator at creation. (Archibald, "Unhandled rejections".)
  ```ts
  // Wrong: if a rejects, b's rejection is unhandled
  const a = fetchA();
  const b = fetchB();
  const x = await a;
  const y = await b;

  // Right
  const [x, y] = await Promise.all([fetchA(), fetchB()]);
  ```
- Choose the combinator by its failure semantics: `Promise.all` rejects on the first rejection (the rest keep running, their results discarded); `allSettled` never rejects, so each result's `status` must be inspected; `any` resolves with the first fulfilment; `race` settles with the first settlement. None of them cancels the losers.
- `Promise.all(items.map(fn))` over an unbounded input opens every connection at once. Fan-out over user-sized or data-sized collections needs a concurrency limit (a pool, `p-map` with `concurrency` set, or batching).

### Strong defaults

- Independent awaits run concurrently; `await` in a loop sums the latencies. Keep them sequential when order, rate limits, or back-pressure matter, and say so when it isn't obvious.

### Review questions

- Are these awaits sequential on purpose?
- What is the largest collection this `Promise.all` can receive?
- With `allSettled`, are the rejected results actually inspected?

## 5. Cancellation & timeouts

### Hard rules

- Every outbound call that can hang has a deadline. `fetch` has no default timeout.
- An async API that does I/O accepts an `AbortSignal` and passes it down; an abandoned operation (navigation, client disconnect, a superseded request, a lost `race`) is aborted, not left running.
  ```ts
  const signal = AbortSignal.any([AbortSignal.timeout(5_000), controller.signal]);
  const res = await fetch(url, { signal });
  ```
- Distinguish the reasons: `AbortSignal.timeout` aborts with a `TimeoutError`, a manual abort with an `AbortError`. Swallowing every abort as "cancelled" hides timeouts.

### Strong defaults

- `signal.throwIfAborted()` at checkpoints in long loops; an `abort` listener is added with `{ once: true }`.
- A retry loop has a bound, a backoff, and stops on abort.

### Review questions

- If the caller gives up, does this work stop?
- What happens when this request never responds?

## 6. Resources, listeners & lifetimes

### Hard rules

- Whatever is acquired is released on every path, including throws and early returns: handles, connections, locks, timers, stream readers. Use `try`/`finally`, or `using` / `await using` (TS 5.2) for a disposable, which releases in reverse order on every exit.
- Every `addEventListener` / `on` / `subscribe` / `setInterval` has a matching removal with the same lifetime as its owner. An anonymous listener cannot be removed; pass `{ signal }` and abort to remove a group. A `MaxListenersExceededWarning` is a leak report, not noise.
- Breaking out of a `for await` calls the iterator's `return()`; a generator holding a resource must release it in `finally`.

### Strong defaults

- A long-lived closure keeps alive everything in the scope it shares, including large values it never references (Archibald, "Garbage collection and closures"). Keep big data out of scopes shared with long-lived callbacks.
- A pipeline of streams uses `pipeline()` so errors propagate and every stream is destroyed.

### Review questions

- Where is this listener or timer removed, and is that reachable on the error path?

## 7. Don't block the event loop

### Hard rules

- One thread runs every callback. Synchronous work on a request path stalls every other request: `*Sync` file, crypto, zlib, and child-process APIs; `JSON.parse` / `JSON.stringify` of large payloads; a loop over an unbounded input; a regular expression with nested quantifiers or overlapping alternation on user input (ReDoS). (Node, "Don't Block the Event Loop".)
- `await` does not make CPU work asynchronous. An `async` function that computes for 200ms blocks for 200ms.

### Strong defaults

- Bound input sizes at the boundary. Move CPU-bound work to a worker pool; workers help with CPU, not I/O. Never spawn a process or worker per request.

### Review questions

- How long can this callback run on the largest realistic input?

## 8. What makes an async finding blocking

Usually blocking:
- a floating promise, or an `async` callback passed to `forEach` / an event emitter / a timer
- a promise used as a boolean; an un-awaited call inside a `try` that was meant to catch it
- `return promise` inside `try`/`catch` where the `catch` is supposed to handle the failure
- promises started eagerly and awaited one by one, leaving a rejection unhandled
- `Promise.allSettled` results never inspected, or `Promise.all` where one failure must not discard the rest
- unbounded `Promise.all` fan-out over input-sized data
- an outbound call with no timeout on a request path; a leaked listener, timer, or handle
- synchronous I/O, heavy CPU, or a ReDoS-prone regex on the event loop

Usually suggestion:
- sequential awaits that could run concurrently
- an async API that takes no `AbortSignal`
- manual `try`/`finally` cleanup where `using` or `{ signal }` fits
- a `.then` chain mixed into an `async` function

Usually nit:
- an `async` keyword on a function that returns a promise directly and has no `try`
