# Correctness & Concurrency Review Rules

The highest-priority lens. A correctness or safety bug outranks every style concern. Python is dynamically typed and has no compile-time race detection, so the blocking concerns are **mutable-default bugs, identity/equality confusion, swallowed exceptions, resource leaks, broken equality/hash contracts, numeric traps, and data races**. Grounded in *Effective Python*, *Fluent Python*, and the Ruff correctness lints. (The asyncio lens lives in `async.md`; this file covers single-threaded correctness and the threading/GIL story.)

## 1. Mutable default arguments

### Hard rules

- `def f(x=[])` / `def f(x={})` / `def f(x=set())` evaluates the default **once at definition time** and shares it across all calls — a classic silent bug where state leaks between calls. (Ruff `B006`.)
  ```python
  def append(item, into=None):
      if into is None:
          into = []
      into.append(item)
      return into
  ```
- The same applies to any mutable or call-time-sensitive default (a `datetime.now()`, an object): use `None` and build inside.

### Review questions

- Does any default argument hold a list/dict/set/object that accumulates across calls?

## 2. Identity vs equality, truthiness

### Hard rules

- `x is None` / `is not None`, never `== None`. Use `is`/`is not` only for `None`, the singletons `True`/`False`, and unique sentinels — never to compare string/int values (`x is "foo"` is a bug; Ruff/`F632`).
- Distinguish absence from emptiness: `if x is None:` when `0`/`""`/`[]`/`0.0` are valid values, not `if not x:`. A truthiness check that treats a valid empty/zero value as "missing" is a finding.

## 3. Late-binding closures

### Hard rules

- A closure captures the *variable*, not its value at creation. Building closures/lambdas in a loop that reference the loop variable all see its final value:
  ```python
  # Wrong: every callback sees the last i
  callbacks = [lambda: i for i in range(3)]
  # Right: bind per-iteration
  callbacks = [lambda i=i: i for i in range(3)]   # or functools.partial
  ```
- Watch the same trap with deferred work submitted to executors/`create_task` inside a loop.

## 4. Exception-handling correctness

### Hard rules

- Never `except:` (bare) — it swallows `SystemExit`/`KeyboardInterrupt`. Never silently swallow with `except Exception: pass` ("errors should never pass silently", Zen). To intentionally ignore, use `contextlib.suppress(SpecificError)` or catch the specific type with a one-line reason.
- Catch the narrowest exception, around the smallest scope. A broad `except Exception` belongs only at a deliberate boundary (a top-level handler, a retry), and must do something real.
- Chain causes with `raise ... from err`; don't drop the original traceback.
- No `return`/`break`/`continue` inside a `finally:` — it silently discards a pending exception (Ruff `B012`).
- Don't both log and re-raise the same exception at one layer.

### Review questions

- Is an exception caught and discarded on a path that can actually fail?
- Is a cause dropped when an exception is translated?

## 5. Resource leaks

### Hard rules

- Every file/socket/lock/DB session/`subprocess`/`tempfile` is acquired with `with` so it closes on every path, including exceptions. A bare `open(...)` whose handle is never closed (or closed only on the happy path) is a finding.
- A generator that holds a resource open across `yield` must be closed (use a context manager, or `contextlib.closing`); relying on GC to close it is non-deterministic.

## 6. Equality & hashing contracts

### Hard rules

- If you define `__eq__`, you **must** define a consistent `__hash__` (over the same fields), or set `__hash__ = None` to make the type explicitly unhashable. Defining `__eq__` alone silently makes instances unhashable (can't be dict keys / set members) — a subtle break. Prefer letting `@dataclass(frozen=True)` generate both.
- Don't use a mutable object as a dict key / set member if the fields its `__hash__` depends on can change after insertion — it gets lost in the table.
- `@dataclass(order=True)` or `functools.total_ordering` for ordering — don't hand-roll a partial set of `__lt__`/`__gt__` that's inconsistent with `__eq__`.

### Review questions

- Was `__eq__` added without a matching `__hash__`?
- Is a mutable instance used as a hash key?

## 7. Numeric & type traps

### Hard rules

- Never use `float` for money or exact decimal arithmetic — use `decimal.Decimal` (and construct it from a string, `Decimal("0.1")`, not a float).
- Be aware of integer/float division (`/` is float, `//` floors) and that `bool` is an `int` subclass (`True == 1`).
- Don't compare floats with `==`; use `math.isclose`.

## 8. The GIL, threads & processes

### Hard rules

- Shared mutable state accessed by multiple threads must be synchronized (a `threading.Lock`/`RLock`, a `queue.Queue`, or confinement). The GIL makes individual bytecode atomic but does **not** make compound operations (`count += 1`, check-then-act) atomic — those still race.
- CPU-bound work doesn't scale on threads (the GIL serializes Python bytecode) — use `ProcessPoolExecutor`/`multiprocessing`. Threads (`ThreadPoolExecutor`) help **I/O-bound** work, where the GIL is released during I/O.
- Establish a consistent lock-acquisition order; don't hold a lock across blocking I/O or a callback into foreign code. Prefer immutability/confinement so you need no lock.
- A `Future` from an executor swallows the task's exception until you call `.result()`; check it. Shut executors down (`with ThreadPoolExecutor() as ex:` or explicit `shutdown`).

### Review questions

- Is shared mutable state mutated from multiple threads without a lock or a queue?
- Is a compound action (`+=`, check-then-act) on shared state assumed atomic?
- Is CPU-bound work placed on threads where the GIL will serialize it?

## 9. Asyncio entry points (see `async.md`)

If the PR introduces or changes `async def`, `await`, `asyncio`, `create_task`, `gather`, `TaskGroup`, or an event loop, switch to the `async.md` lens.

## 10. What makes a correctness finding blocking

Usually blocking:
- a mutable default argument accumulating state across calls
- `== None`/identity-vs-value confusion or a truthiness check that mis-handles a valid empty/zero value, producing wrong results
- a late-binding closure capturing the loop variable
- a swallowed/bare-`except` exception, a lost cause, or `return` in `finally`, on a path that can fail
- a resource leak (file/lock/session not in a `with`)
- `__eq__` without a consistent `__hash__`, or a mutable hash key
- `float` for money, or float `==` comparison, yielding wrong results
- a data race: unsynchronized shared mutable state across threads, or a compound action assumed atomic
- a blocked event loop / asyncio misuse (see `async.md`)

Usually suggestion:
- broad `except Exception` where a specific type fits
- CPU-bound work on threads where processes are warranted (perf, not correctness, unless it deadlocks)
- a mutable field/attribute that could be `frozen`/immutable

Usually nit:
- exception message wording
- a `with` scope that could tighten for readability
