# Example Review Comments (Python)

Use these as a tone and quality reference. Terse, concrete, with an idiomatic fix.

## Good example — Mutable default argument (blocking)

- **File:** `app/cart.py:14`
- **Title:** Mutable default `items=[]` is shared across all calls
- **Why it matters:** `def add(item, items=[])` evaluates the list once at definition time, so every call without `items` mutates the *same* list — state leaks between unrelated calls. (Ruff `B006`.)
- **Recommendation:** Default to `None` and build inside:
  ```python
  def add(item, items=None):
      if items is None:
          items = []
      items.append(item)
      return items
  ```
- **Confidence:** high

## Good example — Swallowed exception (blocking)

- **File:** `app/sync.py:52`
- **Title:** Bare `except` discards every error, including the cause
- **Why it matters:** `try: push(record) except: pass` swallows all exceptions (even `KeyboardInterrupt`/`SystemExit`) and hides real failures — "errors should never pass silently" (Zen). A failed push is now indistinguishable from success.
- **Recommendation:** Catch the specific error and either handle or propagate it, chaining the cause:
  ```python
  try:
      push(record)
  except PushError as err:
      raise SyncError(f"failed to push {record.id}") from err
  ```
- **Confidence:** high

## Good example — Data race (blocking)

- **File:** `app/metrics.py:20`
- **Title:** `self.count += 1` from worker threads is not atomic
- **Why it matters:** `count += 1` is a read-modify-write; the GIL makes individual bytecodes atomic but not this compound operation, so concurrent workers lose increments. Shared mutable state needs synchronization or confinement.
- **Recommendation:** Guard it with a lock, or push counts through a `queue.Queue` and aggregate on one thread:
  ```python
  with self._lock:
      self.count += 1
  ```
- **Confidence:** high

## Good example — `__eq__` without `__hash__` (blocking)

- **File:** `app/models.py:33`
- **Title:** Custom `__eq__` without `__hash__` makes instances unhashable
- **Why it matters:** Defining `__eq__` alone sets `__hash__` to `None`, so `Money` can no longer be a dict key or set member — any such use raises `TypeError`, and equal values would otherwise hash inconsistently.
- **Recommendation:** This is an immutable value — make it a frozen dataclass and delete the hand-written `__eq__`:
  ```python
  @dataclass(frozen=True)
  class Money:
      amount_minor: int
      currency: str
  ```
- **Confidence:** high

## Good example — Blocking the event loop (blocking)

- **File:** `app/worker.py:41`
- **Title:** `time.sleep` inside a coroutine stalls the whole event loop
- **Why it matters:** `async def poll(): ... time.sleep(5)` blocks the single event-loop thread, freezing every other task for 5s. Synchronous sleeps/I/O don't yield to the loop.
- **Recommendation:** Use the async sleep (or `asyncio.to_thread` for unavoidable blocking I/O):
  ```python
  await asyncio.sleep(5)
  ```
- **Confidence:** high

## Good example — Idiom & naming (suggestion)

- **File:** `app/report_utils.py:8`
- **Title:** `range(len(...))` indexing and a `report_utils` junk-drawer module
- **Why it matters:** `for i in range(len(rows)): row = rows[i]` is the anti-idiom — `enumerate` reads better and can't go out of range (Hettinger). And `report_utils` is a bag of unrelated functions, a cohesion smell.
- **Recommendation:** `for i, row in enumerate(rows):`; move each function onto the type it operates on or into a focused module, and delete `report_utils`.
- **Confidence:** high

## Good example — Typing precision (suggestion)

- **File:** `app/api.py:27`
- **Title:** Public function returns bare `dict` with `Optional`/legacy typing
- **Why it matters:** `def find(id) -> Optional[dict]` tells the caller nothing about the shape and uses legacy forms. A loose dict invites `KeyError`s the checker can't catch.
- **Recommendation:** Return a typed value and use modern syntax: a `@dataclass` (or `TypedDict` at the boundary) and `Result | None`:
  ```python
  def find(id: UserId) -> User | None: ...
  ```
- **Confidence:** medium

## Good example — Consistency clearly labeled (suggestion)

- **File:** `app/format.py:21,47`
- **Title:** File mixes `"{}".format(...)` and f-strings for the same purpose
- **Why it matters:** Line 21 uses `"{}: {}".format(name, count)`; line 47 uses `f"{name}: {count}"` for the same kind of interpolation. The variety is noise; f-strings are canonical (`consistency.md`).
- **Recommendation:** Use the f-string in both. Strong default, not a hard rule. (Keep `%`-style only for `logging` call args.)
- **Confidence:** medium

## Good example — Design question handed off

- **File:** `app/pricing.py:8`
- **Title:** `PricingStrategy` ABC may be premature abstraction
- **Why it matters:** The ABC has one subclass and one caller; the inheritance and registration add indirection without a second strategy in sight.
- **Recommendation:** Use the concrete class (or a plain function) for now; introduce the abstraction when a second model lands.
- **Confidence:** medium
- → `/python-expert Should pricing variation be an ABC, a Protocol, or just a function until a second model exists?`

## Bad example

> Naming could be better and you should probably handle that exception.

Why this is bad:
- no file/line
- no explanation of impact
- no concrete idiomatic fix
- no severity, no confidence
