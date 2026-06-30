# Asyncio Review Rules

Asyncio adds a concurrency model with its own failure modes that neither the runtime nor the type checker polices: blocking the event loop, task lifetimes, cancellation, and exception aggregation are the reviewer's job. This lens pairs with `correctness-concurrency.md`. Grounded in the `asyncio` docs, *Effective Python*'s concurrency chapter, and David Beazley's concurrency talks.

## 1. Don't block the event loop

### Hard rules

- Never call a blocking operation inside an `async def` running on the event loop: `time.sleep`, synchronous file/network I/O (`requests`, `open().read()` on large files), a long CPU loop, or a blocking DB driver. One blocked coroutine stalls **every** task on that loop.
- Use the async-native call: `await asyncio.sleep(...)`, an async HTTP client (`aiohttp`/`httpx.AsyncClient`), an async DB driver. For unavoidable blocking/CPU work, offload it: `await asyncio.to_thread(fn, ...)` (blocking I/O) or a `ProcessPoolExecutor` via `loop.run_in_executor` (CPU-bound).
- Don't call `asyncio.run(...)` inside a library function or inside already-running async code — it creates/closes a loop and raises if one is already running. Libraries expose `async def`; the application owns the one `asyncio.run` at the top.

### Review questions

- Does any `await`-bearing function call a synchronous blocking API (`time.sleep`, `requests`, sync DB)?
- Is `asyncio.run` called anywhere but the application entry point?

## 2. TaskGroup over bare gather

### Strong defaults

- Prefer `asyncio.TaskGroup` (3.11+) to `asyncio.gather` for structured fan-out: a child failure cancels the siblings and the errors surface as an `ExceptionGroup`, and the `async with` block won't exit until all children finish. `gather` without `return_exceptions` cancels nothing on the first error and can orphan the rest; with `return_exceptions=True` it silently hides failures in the result list.
  ```python
  async with asyncio.TaskGroup() as tg:
      tg.create_task(fetch(a))
      tg.create_task(fetch(b))
  ```
- If you use `gather`, decide deliberately how failures and cancellation propagate, and handle the returned exceptions — don't drop them.

### Review questions

- Could a `gather` leave sibling tasks running after one fails?
- Are exceptions from `gather(..., return_exceptions=True)` actually inspected?

## 3. Cancellation

### Hard rules

- A task can be cancelled at any `await`; `asyncio.CancelledError` propagates through it. Don't swallow `CancelledError` in a broad `except Exception`/`except:` — on 3.8+ it derives from `BaseException`, but a bare `except` or an `except BaseException` that eats it breaks cancellation. If you catch it for cleanup, **re-raise** it.
- Release resources on cancellation with `try/finally` or an async context manager; don't leave a half-finished transaction/partial write when the task is cancelled at an `await`.
- Wrap a section that must not be cancelled mid-way with `asyncio.shield` deliberately (and know it still cancels at the next await).

### Review questions

- If this coroutine is cancelled at this `await`, is any state left inconsistent or a resource left open?
- Is `CancelledError` caught and not re-raised?

## 4. Task lifetimes & fire-and-forget leaks

### Hard rules

- `asyncio.create_task(...)` returns a task you must keep a reference to — the loop holds only a **weak** reference, so a task whose handle is discarded can be garbage-collected mid-flight and silently never finish. Store it (e.g. in a set with a done-callback to discard), await it, or use a `TaskGroup`.
- A fire-and-forget task with no owner is the asyncio analog of a leaked thread: its exceptions vanish (surfaced only as "Task exception was never retrieved" at GC), and nothing cancels it on shutdown. Know where every task stops.
- On shutdown / parent failure, cancel and await child tasks; don't orphan them.

### Review questions

- Is a `create_task` result discarded (GC-leak risk), or is the task owned/awaited?
- Where does this task exit, and who cancels it on shutdown?

## 5. Async context managers, generators & iteration

### Strong defaults

- Use `async with` for async resources (an `aiohttp.ClientSession`, an async DB connection) so they close on every path; don't manually open/close around `await`s.
- Close async generators (`aclose`, or iterate them fully) — an async generator suspended at a `yield` holding a resource leaks if abandoned.
- `async for` over an async iterator; don't block-collect an async stream just to re-iterate it.

## 6. Mixing sync and async

### Hard rules

- Calling an `async def` without `await` (and without scheduling it as a task) produces a coroutine object that **never runs** — dead code that often emits "coroutine was never awaited". Treat an un-awaited coroutine as a finding.
- Don't share a non-thread-safe asyncio primitive across threads; asyncio objects are bound to their loop.

### Review questions

- Is an `async def` called without `await`/`create_task` (silently doing nothing)?

## 7. What makes an async finding blocking

Usually blocking:
- a blocking call (`time.sleep`, sync I/O, heavy CPU) inside a coroutine on the event loop
- `asyncio.run` inside a library or already-running loop
- a swallowed `CancelledError` (breaks cancellation), or state/resources left inconsistent on cancellation
- a fire-and-forget `create_task` with a discarded reference (GC leak) or no shutdown path
- an un-awaited coroutine that was supposed to run
- a `gather` that orphans siblings on failure or hides their exceptions

Usually suggestion:
- `gather` where a `TaskGroup` would give structured cancellation and error aggregation
- manual open/close of an async resource where `async with` fits
- independent awaits serialized where they could run concurrently

Usually nit:
- a task naming/organization choice that works but isn't the clearest
