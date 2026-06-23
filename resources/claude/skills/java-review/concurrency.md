# Concurrency & the Java Memory Model Review Rules

Java's concurrency story is large and the compiler polices almost none of it: visibility, atomicity, lock discipline, thread lifetimes, and the memory model are the reviewer's job. This lens pairs with `correctness-concurrency.md`. Grounded in *Java Concurrency in Practice* (Brian Goetz et al.), *Effective Java* 3rd ed. (Items 78–84), the `java.util.concurrent` Javadoc, and the virtual-threads JEPs (444, 491, structured concurrency).

## 1. The Java Memory Model: visibility & atomicity

### Hard rules

- Reads and writes of shared mutable state from multiple threads **must** be coordinated — without a `happens-before` relationship, a writing thread's update may never become visible to a reader, even forever (*Effective Java* Item 78; *JCiP* visibility chapter). This is not a timing bug you can sleep your way around; it's a memory-model guarantee that simply isn't there.
- `synchronized` (on the same lock) and `volatile` both establish `happens-before`. Use `volatile` for a single flag/reference where only *visibility* is needed (no compound action). Use `synchronized`/`Lock`/atomics when you also need *atomicity*.
- A 64-bit `long`/`double` write is not guaranteed atomic without `volatile` — a non-`volatile` `long` can be seen half-updated. (*JCiP*.)
- `volatile` does **not** make `count++` atomic — read-modify-write is three operations. Use `AtomicInteger`/`AtomicLong`/`LongAdder` or a lock.

### Review questions

- Is a field written by one thread and read by another without `synchronized`/`volatile`/an atomic?
- Is a `volatile` field used for a compound action (`++`, check-then-set) that needs atomicity?

## 2. Atomicity of compound actions

### Hard rules

- Check-then-act and read-modify-write are races even on thread-safe collections: `if (!map.containsKey(k)) map.put(k, v);` is not atomic. Use `putIfAbsent`/`computeIfAbsent`/`merge` on `ConcurrentHashMap`, or hold a lock for the whole compound action. (*JCiP*; Error Prone `ModifyingCollectionWithItself` and friends flag adjacent cases.)
- When an invariant spans multiple state variables, every variable in it must be guarded by the **same** lock (*JCiP*). Two individually-thread-safe fields don't make a thread-safe invariant.

### Review questions

- Is a check-then-act done on a shared collection without an atomic operation or a lock?
- Does an invariant span two fields guarded by different locks (or by a concurrent collection that doesn't cover the compound action)?

## 3. Lock discipline & deadlocks

### Hard rules

- Establish a consistent lock-acquisition order; acquiring two locks A→B on one path and B→A on another is a deadlock waiting to happen (*JCiP* deadlock chapter).
- Hold a lock for the shortest scope; don't perform blocking I/O, a network/RPC call, or a callback into foreign code while holding a lock (a long critical section serializes everyone and can deadlock through re-entrant foreign code).
- Prefer immutability and confinement so you don't need a lock at all (*JCiP* — immutable objects are inherently thread-safe). Don't synchronize excessively (*Effective Java* Item 79) — never call an alien/overridable method while holding a lock.
- Don't synchronize on a value that may be reused or interned (a boxed `Integer`, a `String` literal, `this` when the instance is publicly lockable) — use a `private final Object lock = new Object();`.

### Review questions

- Could two paths lock A→B and B→A?
- Is a lock held across I/O, a callback, or an alien method call?
- Is the lock object safely private, or can outside code lock on the same monitor?

## 4. Prefer the high-level utilities

### Hard rules

- Prefer `java.util.concurrent` to `wait`/`notify` (*Effective Java* Item 81): `CountDownLatch`, `Semaphore`, `CyclicBarrier`, `BlockingQueue`, `CompletableFuture`, `ConcurrentHashMap`, `CopyOnWriteArrayList`, the atomics. New `wait`/`notify` code is a finding unless there's a specific reason.
- Prefer executors and tasks to managing raw `Thread`s (Item 80). Submitting `Runnable`/`Callable` to an `ExecutorService` separates task submission from execution policy.
- A `wait` is always inside a `while` loop re-checking the condition (never an `if`) — guard against spurious wakeups (Item 81).

### Review questions

- Is there hand-rolled `wait`/`notify` where a `CountDownLatch`/`BlockingQueue`/`CompletableFuture` is the idiom?
- Is a `wait` guarded by `if` instead of `while`?

## 5. Thread & task lifetimes

### Hard rules

- Know where every thread/task stops (the Java analog of "before you launch a goroutine, know when it stops"). A submitted task that loops without a termination/interruption path lives until the JVM dies.
- An `ExecutorService` must be shut down (`shutdown()` then `awaitTermination`, or try-with-resources / `close()` on JDK 19+). A leaked executor leaks non-daemon threads and prevents clean exit.
- Handle `InterruptedException` correctly: either propagate it or restore the interrupt status with `Thread.currentThread().interrupt()` — never swallow it, or you break cancellation (*JCiP* cancellation chapter).
- Don't ignore the `Future` returned by `submit` — an exception thrown by the task is swallowed until you call `get()`. Check it or use `CompletableFuture` with an exception handler.

### Review questions

- Where does this task/thread exit? If "when the process dies", it's a leak under churn.
- Is the executor shut down on every path, including failure?
- Is `InterruptedException` propagated or the interrupt restored?

## 6. Virtual threads (JEP 444)

### Strong defaults

- A virtual thread is cheap — create one per task (`Executors.newVirtualThreadPerTaskExecutor()` or `Thread.ofVirtual().start(...)`) and let it block on I/O. **Never pool virtual threads** — a pool defeats their purpose.
- To limit concurrent access to a downstream resource, use a `Semaphore`, **not** a small pool of virtual threads.
- Don't run CPU-bound work on virtual threads — keep a bounded platform-thread pool sized to the cores for that.
- Pinning: before JDK 24, a virtual thread inside a `synchronized` block/method pins its carrier; if it blocks there frequently/long it can starve the scheduler — prefer `ReentrantLock` around blocking I/O on those versions. JEP 491 (JDK 24+) removes pinning for `synchronized`, so on JDK 24/25 `synchronized` is safe (JFR `jdk.VirtualThreadPinned` monitoring still useful). State which JDK the project targets.
- Don't store per-request state in a `ThreadLocal` and assume pooling-style reuse — with one virtual thread per task, prefer passing state explicitly or scoped values.

### Review questions

- Are virtual threads pooled, or is concurrency to a downstream bounded with a pool instead of a `Semaphore`?
- Is CPU-bound work placed on virtual threads?
- On a pre-JDK-24 target, does a hot `synchronized` block guard blocking I/O (pinning risk)?

## 7. Structured concurrency

### Strong defaults

- Where available, prefer structured concurrency (`StructuredTaskScope`) to fork-and-forget: child tasks are scoped to a block, errors propagate, and cancellation is automatic — no orphaned tasks on early return or failure.
- A `CompletableFuture` fan-out should join all branches and propagate failures (`allOf` + per-future exception handling, or `exceptionally`/`handle`), not fire-and-forget and drop exceptions.

## 8. What makes a concurrency finding blocking

Usually blocking:
- unsynchronized shared mutable state (missing `happens-before`): a field written by one thread, read by another, with no `synchronized`/`volatile`/atomic
- a non-atomic compound action (check-then-act, `++` on `volatile`) on shared state
- a deadlock: lock-order inversion, or a lock held across blocking I/O / an alien call
- a leaked/never-shut-down `ExecutorService`, or a task/thread with no stop condition
- a swallowed `InterruptedException` (breaks cancellation)
- pooling virtual threads, or CPU-bound work on virtual threads at scale
- an assertion thrown inside a worker thread that the test thread never observes (see `testing.md`)

Usually suggestion:
- hand-rolled `wait`/`notify` where a `java.util.concurrent` utility fits
- `synchronized` where confinement/immutability would remove the need
- a `CompletableFuture` fan-out that drops a branch's exception
- synchronizing on a non-private/interned lock object

Usually nit:
- a `volatile` that could be documented as visibility-only
- a lock scope that could tighten a few lines for clarity
