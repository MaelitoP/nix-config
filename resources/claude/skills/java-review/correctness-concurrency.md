# Correctness & Concurrency Review Rules

The highest-priority lens. A correctness or safety bug outranks every style concern. Java has no borrow checker and no compile-time race detection, so the blocking concerns are **reachable `NullPointerException`s, resource leaks, broken equality/ordering contracts, swallowed exceptions, numeric traps, and data races**. Grounded in *Effective Java* 3rd ed., *Java Concurrency in Practice*, and the Error Prone / SpotBugs bug-pattern catalogs. (The deep concurrency lens — the JMM, synchronization, executors, virtual threads — lives in `concurrency.md`; this file covers single-threaded correctness and the concurrency entry points.)

## 1. NullPointerException on reachable paths

### Hard rules

- A method that can return `null` must be handled at every call site, or it shouldn't return `null` (return an empty collection — *Effective Java* Item 54 — or `Optional` as a return type — Item 55).
- Validate parameters and fail fast with `Objects.requireNonNull(x, "x")` (Item 49). An unchecked field dereference of a parameter that can be `null` is a finding.
- **Auto-unboxing a `null` boxed value throws NPE.** `int n = map.get(key);` where `get` can return `null` (a missing key, a `null` value) NPEs silently. Use the primitive deliberately and guard. (SpotBugs `NP_UNBOXING_NULL`, Error Prone `UnnecessaryBoxedVariable`.)
- `Optional.get()` without `isPresent()`/`orElse` is a finding (Error Prone `OptionalGetWithoutIsPresent`).

### Review questions

- Can this dereference receive `null` from a map lookup, an unset field, an external API, or a `null` return?
- Is a boxed type auto-unboxed where it could be `null`?

## 2. Resource leaks

### Hard rules

- Every `AutoCloseable`/`Closeable` (streams, readers, `Connection`/`Statement`/`ResultSet`, `InputStream`, `HttpClient` bodies, `Stream` from `Files.lines`) must be closed in **try-with-resources**, not a hand-written try/finally that can skip `close()` on an exception. (Error Prone `StreamResourceLeak`, SpotBugs `OBL_UNSATISFIED_OBLIGATION`.)
- An `ExecutorService` must be shut down (`shutdown()`/`close()` on JDK 19+, or try-with-resources). A leaked executor keeps non-daemon threads alive and leaks the pool.
- Don't return a `Stream` backed by an open resource without documenting that the caller must close it.

### Review questions

- Is a resource opened on a path where an exception can skip its `close()`?
- Is an `ExecutorService`/`Closeable` created and never shut down/closed?

## 3. Exception-handling correctness

### Hard rules

- Never swallow an exception with an empty `catch` (*Effective Java* Item 77). If a catch is genuinely safe to ignore, it carries a one-line comment saying why and the variable is named `ignored`.
- Don't catch `Exception`/`Throwable`/`RuntimeException` broadly to "be safe" — it hides bugs (including `InterruptedException` and `Error`). Catch the specific type.
- When translating an exception, chain the cause (`new XException("context", cause)`) — losing the cause erases the stack trace (Item 73).
- Catching `InterruptedException` must either restore the interrupt (`Thread.currentThread().interrupt()`) or propagate it — never swallow it (see `concurrency.md`).
- Don't both log and rethrow at the same layer (double reporting).
- Strive for failure atomicity: validate before mutating so a thrown exception leaves the object in its prior state (Item 76).

### Review questions

- Is an exception caught and discarded on a path that can actually fail?
- Is a cause dropped when an exception is translated?
- Is `InterruptedException` swallowed?

## 4. Equality, hashing & ordering contracts

### Hard rules

- If you override `equals`, you **must** override `hashCode`, over the same fields, consistently (*Effective Java* Item 10, Item 11; Error Prone `EqualsHashCode`). The reverse — overriding `hashCode` only — is also a finding.
- `equals` must honor the contract: reflexive, symmetric, transitive, consistent, and `x.equals(null) == false`. A subclass adding a value component generally can't preserve symmetry/transitivity with its superclass — prefer composition.
- Prefer a `record` so the compiler generates `equals`/`hashCode`/`toString` correctly over the components.
- `compareTo` must be consistent with `equals` where practical (Item 14) and must not use subtraction (`a - b`) that overflows — build it with `Comparator.comparing(...).thenComparing(...)` or `Integer.compare`.
- Don't use a mutable object as a `HashMap` key / `HashSet` element if the fields in its `hashCode` can change after insertion.

### Review questions

- Was `equals` or `hashCode` overridden without the other, or over different fields?
- Does `compareTo` use overflow-prone subtraction, or is it inconsistent with `equals`?

## 5. Numeric & type traps

### Hard rules

- Integer overflow wraps silently. Use `Math.addExact`/`multiplyExact` (throws on overflow) or `long`/`BigInteger` when values can be large. (*Effective Java* Item 60.)
- `int` division truncates: `1 / 2 == 0`; cast a operand to `double` if you want a fraction, or use `BigDecimal`.
- Never use `float`/`double` for money or any value needing exact decimal arithmetic — use `BigDecimal` (Item 60). And compare `BigDecimal` with `compareTo`, not `equals`.
- `==` on `String` or boxed numbers compares identity, not value — use `.equals`/`Objects.equals`. (Error Prone `ReferenceEquality`, SpotBugs `ES_COMPARING`.)
- An `as`/narrowing cast (`(int) aLong`) truncates silently — guard the range.

## 6. Defensive copies

### Hard rules

- Make a defensive copy of a mutable parameter you store and of mutable internal state you return — arrays, `Date`, `Collection`, `Map` (*Effective Java* Item 50). Copy *before* validating, and validate the copy (TOCTOU). Return an unmodifiable view or a copy, never the live internal collection.

### Review questions

- Does a constructor store a caller's mutable array/collection/`Date` directly?
- Does a getter return the live internal mutable collection?

## 7. Collections & iteration

### Strong defaults

- Modifying a collection while iterating it (outside the iterator's own `remove`) throws `ConcurrentModificationException` — use `Iterator.remove`, `removeIf`, or collect-then-remove.
- `List.of`/`Map.of`/`Arrays.asList` return fixed-size/immutable lists; mutating them throws `UnsupportedOperationException`. Wrap in `new ArrayList<>(...)` if you need to mutate.
- Beware `subList`/`Arrays.asList` views aliasing the backing array.

## 8. Concurrency entry points (see `concurrency.md`)

If the PR introduces or changes **any** of these, switch to the `concurrency.md` lens:
- a new `Thread`, `ExecutorService`, virtual thread, or `CompletableFuture`
- `synchronized`, `volatile`, a `Lock`, an atomic, or a concurrent collection
- shared mutable state reachable from more than one thread
- `wait`/`notify`, `join`, `CountDownLatch`, `Semaphore`

## 9. What makes a correctness finding blocking

Usually blocking:
- a reachable `NullPointerException` (unchecked null return, null-unboxing) on real input
- a resource leak (`AutoCloseable`/executor not closed on an exception path)
- a swallowed/discarded exception, or a lost cause, on a path that can fail; a swallowed `InterruptedException`
- `equals` without `hashCode` (or vice versa), a broken `equals`/`compareTo` contract, or a mutable hash key
- silent integer overflow / `int`-division / narrowing-cast / `==`-on-reference that yields wrong results; `double` for money
- a missing defensive copy that lets a caller mutate internal state
- a data race / unsynchronized shared mutable state (see `concurrency.md`)

Usually suggestion:
- broad `catch (Exception)` where a specific type fits
- a mutable field that could be `final`/immutable
- a `subList`/`asList` aliasing risk that's currently safe

Usually nit:
- exception message wording
- a guard that could move a few lines for readability
