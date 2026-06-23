# Java Philosophy & Principles

The principles that ground every recommendation. Sources: *Effective Java* 3rd ed. (Joshua Bloch), *Java Concurrency in Practice* (Brian Goetz, Tim Peierls, Joshua Bloch, Joseph Bowbeer, David Holmes, Doug Lea), Brian Goetz's modern-Java writing (*Data-Oriented Programming in Java*, the records / sealed types / pattern matching JEPs, virtual threads / Project Loom), the *Google Java Style Guide*, the *Oracle Code Conventions*, and the OpenJDK *Local Variable Type Inference Style Guidelines* (Stuart Marks). Cite these by name when advising.

## The overriding value: minimize mutability and encode correctness in types

- **Minimize mutability.** Make classes immutable unless there's a strong reason not to: `private final` fields, no mutators, no subclassing, defensive copies in and out. Immutable objects are simple, freely shareable, and inherently thread-safe. (*Effective Java* Item 17; *JCiP* — "the single most important rule is to prefer immutability".)
- **Make illegal states unrepresentable.** Model a closed set of possibilities as a `sealed` interface permitting a known set of `record`s (a sum of products — algebraic data types). A value that exists is, by construction, one of the legal shapes, and `switch` pattern matching over it is exhaustive. (Goetz, *Data-Oriented Programming in Java*.)
- **Use enums, not int/String constants.** A typed enum can't be confused with an unrelated constant, prints meaningfully, and can carry behavior. (*Effective Java* Item 34; Item 62: avoid strings where another type fits.)
- **Validate at the boundary.** Check parameters at the top of public methods and fail fast (`Objects.requireNonNull`, range checks) so the invalid case never propagates inward. (*Effective Java* Item 49.)

## Program to interfaces, not implementations

- **Refer to objects by their interfaces.** Declare fields, parameters, returns, and variables with the interface type (`List`, `Map`, `Collection`) — the implementation becomes a swappable detail. (*Effective Java* Item 64.)
- **Prefer interfaces to abstract classes.** Interfaces permit mixins, multiple inheritance of type, retrofitting onto existing classes, and `default` methods for shared behavior. Use a skeletal implementation (`AbstractList`-style) to ease implementers. (*Effective Java* Item 20.)
- **`var` is for implementation, not API.** Local-variable type inference (`var`) is fine when the initializer makes the type obvious; it never appears on fields, parameters, or returns, because "program to the interface" still governs API contracts — those are declared explicitly. (OpenJDK *LVTI Style Guidelines*, Stuart Marks.)
- **Accept the most general type; return a useful concrete contract.** Take `Collection`/`Iterable`/`List` parameters, not a specific implementation. Return empty collections, never `null` (*Effective Java* Item 54).

## Composition over inheritance

- **Favor composition over inheritance.** Inheritance across package boundaries is fragile: a subclass depends on implementation details of its superclass that can change underneath it. Wrap-and-delegate (the decorator) is safer and more flexible. Inherit only when there's a genuine "is-a" relationship and you control both classes. (*Effective Java* Item 18.)
- **Design and document for inheritance, or prohibit it.** A class meant to be extended documents its self-use of overridable methods; a class not meant to be extended is `final` or has only private constructors. (*Effective Java* Item 19.)
- **In public classes, use accessors, not public fields.** Public mutable fields freeze the representation into the API and skip validation. (*Effective Java* Item 16.)

## Exceptions are values you design, not control flow

- **Use exceptions only for exceptional conditions** — never for ordinary control flow (e.g. terminating a loop by catching an exception). (*Effective Java* Item 69.)
- **Checked for recoverable, unchecked for programming errors.** Use a checked exception when the caller can reasonably recover and you want the compiler to force handling; use a `RuntimeException` for programming errors and unrecoverable conditions. (*Effective Java* Item 70.) But avoid *unnecessary* checked exceptions — overused, they make APIs painful and don't compose with streams/lambdas (Item 71).
- **Favor standard exceptions** (`IllegalArgumentException`, `IllegalStateException`, `NullPointerException`, `IndexOutOfBoundsException`, `UnsupportedOperationException`) over inventing your own. (*Effective Java* Item 72.)
- **Throw exceptions appropriate to the abstraction.** Catch a low-level exception and rethrow one that makes sense at this layer, chaining the cause. (*Effective Java* Item 73.) Include failure-capture information in the message (Item 75). Strive for failure atomicity — a failed call leaves the object in its prior state (Item 76).
- **Never ignore an exception.** An empty `catch` block defeats the purpose; at minimum log and comment why it's safe to swallow. (*Effective Java* Item 77.)

## Modern Java: data-oriented programming

- **Records model data.** A `record` is a transparent, immutable carrier for a fixed set of values; it generates the canonical constructor, accessors, and correct `equals`/`hashCode`/`toString`. Reach for it before a hand-written value class or a Lombok `@Data`. (Records JEP; Goetz.)
- **Sealed types model choices.** A `sealed interface` permitting a known set of subtypes lets the compiler know the whole hierarchy, enabling exhaustive `switch`. Records (product types) + sealed interfaces (sum types) + pattern matching = algebraic data types in Java. (Goetz, *Data-Oriented Programming in Java*.)
- **Pattern matching acts on data.** `instanceof` patterns and `switch` patterns (with deconstruction and guards) replace instanceof-and-cast chains and visitor boilerplate, and the compiler checks exhaustiveness over a sealed type.
- **Prefer expressions to statements.** A `switch` *expression* (arrow form, returns a value, exhaustive) beats a fall-through `switch` statement; a text block beats concatenated string literals; an enhanced `instanceof` beats cast-after-test.

## Concurrency: confine, immobilize, and use the high-level utilities

- **Prefer immutability and confinement.** The easiest thread-safe object is one that's immutable or never shared. Confine mutable state to one thread; share only immutable or properly synchronized state. (*JCiP*.)
- **Synchronize access to shared mutable data.** Reads and writes of shared mutable state must be coordinated — `synchronized`, `volatile` for visibility-only flags, or `java.util.concurrent` atomics. Without it, the Java Memory Model gives no visibility or ordering guarantees. (*Effective Java* Item 78; *JCiP* chapters on visibility and the JMM.)
- **Guard each invariant with one lock.** When an invariant spans multiple state variables, every variable in it must be guarded by the *same* lock. (*JCiP*.)
- **Prefer the concurrency utilities to `wait`/`notify` and to raw threads.** Use `ExecutorService`, `CompletableFuture`, concurrent collections, `CountDownLatch`, `Semaphore` — not hand-rolled `wait`/`notify` and not bare `Thread`. (*Effective Java* Item 80, Item 81.)
- **Virtual threads are cheap; don't pool them.** A virtual thread (JEP 444) is so cheap that you create one per task and let it block on I/O. Never pool virtual threads; bound concurrency to a downstream resource with a `Semaphore`. Keep bounded platform-thread pools for CPU-bound work.
- **Document thread safety.** Every class states its thread-safety level (immutable, thread-safe, conditionally thread-safe, not thread-safe). (*Effective Java* Item 82.)

## Tooling is part of the language

- **The formatter ends formatting debates.** `google-java-format` / Spotless (or a Checkstyle format profile) makes all Java in a repo read the same way — like `gofmt`. Never hand-fight the formatter; uniformity beats preference. (*Google Java Style Guide*.)
- **Listen to the static analyzers.** Error Prone catches bug patterns at compile time; SpotBugs inspects bytecode for correctness/concurrency bugs; PMD flags source smells; Checkstyle enforces style. A warning from these is a finding, not noise.
- **Write tests that lock in public behavior.** JUnit 5 + AssertJ for expressive assertions; parameterized tests over copy-paste; Mockito only at seams the consumer owns. (See `../java-review/testing.md`.)
- **Minimize accessibility.** `private` by default; make the API as small as it can be — every `public` member is a commitment. (*Effective Java* Item 15.)

## Precedents to cite

These usually end a debate — point at the canon:

- Immutable value types: `String`, `Integer`/`Long` (and the boxed types), `java.time.Instant`/`LocalDate`/`Duration`, `java.math.BigDecimal`, `record` types.
- Program-to-interface returns: methods returning `List`/`Map`/`Set`, not `ArrayList`/`HashMap`; `Collections.unmodifiableList`, `List.of(...)`.
- Static factories over constructors: `List.of`, `Map.of`, `Optional.of`/`empty`, `Integer.valueOf`, `Instant.now`, `Stream.of`. (*Effective Java* Item 1.)
- Builders: `StringBuilder`, `Stream.Builder`, `HttpRequest.newBuilder()`, `Locale.Builder`. (*Effective Java* Item 2.)
- Exceptions as designed values: the standard `IllegalArgumentException`/`IllegalStateException`/`NullPointerException`; chained causes via `initCause`/the cause constructor.
- Comparators built compositionally: `Comparator.comparing(...).thenComparing(...)`, `Comparator.naturalOrder()`.
- Concurrency utilities: `ExecutorService`, `CompletableFuture`, `ConcurrentHashMap`, `CopyOnWriteArrayList`, `AtomicInteger`, `CountDownLatch`, `Semaphore`; virtual threads via `Executors.newVirtualThreadPerTaskExecutor()`.
- Algebraic data types: a `sealed interface Shape permits Circle, Square` with `record Circle(double r)`, matched by an exhaustive `switch`.
