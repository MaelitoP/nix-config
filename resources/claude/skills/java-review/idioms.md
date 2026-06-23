# Idioms, API Design & Naming Review Rules

Grounded in *Effective Java* 3rd ed. (the numbered items), Brian Goetz's modern-Java writing (records, sealed types, pattern matching, *Data-Oriented Programming in Java*), the *Google Java Style Guide*, and the Error Prone / SpotBugs / PMD idiom checks. These are how idiomatic Java reads. Deviation needs a reason.

## 1. Naming

### Hard rules

- Casing (*Google Java Style*, *Oracle Code Conventions*): `UpperCamelCase` for classes, interfaces, enums, records, and annotations; `lowerCamelCase` for methods, fields, parameters, and local variables; `UPPER_SNAKE_CASE` for `static final` constants; lowercase, no-underscore for package names.
- Type parameters are single capitals or short `UpperCamelCase`: `T`, `E`, `K`, `V`, `R`.
- A getter is `name()` on a record (no `get` prefix); on a JavaBean it is `getName()` and a boolean is `isActive()`. Don't mix conventions within a type.
- Don't prefix interfaces with `I` (`IService`) or suffix the only implementation with `Impl` just to coin two names — name the interface for the role and the class for how it fills it.

### Common weak names to flag

- `Manager`, `Helper`, `Util`/`Utils`, `Processor`, `Handler` (when not an actual handler), `Data`, `Info`, `Service` (when meaningless), `Base`, `Abstract`-prefix without a skeletal-impl reason, `common`, `misc`.
- A `Util`/`Helpers`/`Common` class full of unrelated `static` methods is almost always a cohesion failure — put the method on the type it operates on, or in a focused class.

### Review questions

- Would a reader predict this method's behavior from its name and the type it's on?
- Does the name describe the domain, or the mechanism?
- Does a class exist only because the author needed somewhere to put a static method?

## 2. Accessibility & API surface

### Hard rules

- Minimize accessibility (*Effective Java* Item 15): `private` by default; widen only as needed. `public`/`protected` members are an API commitment.
- In public classes, expose accessors, not public mutable fields (Item 16). A `public static final` constant of an immutable type is fine; a public mutable array/collection field is a finding (return a copy or an unmodifiable view).
- Prefer immutability (Item 17): `final` fields, no mutators, defensive copies in and out, the class `final` or its constructors private unless designed for inheritance.

### Review questions

- Does a `public`/`protected` member actually need that visibility, or would package-private/`private` do?
- Is a mutable field or array leaked through a getter without a defensive copy?

## 3. Exceptions

### Hard rules

- Use exceptions only for exceptional conditions, never for ordinary control flow (*Effective Java* Item 69).
- Checked exceptions for conditions the caller can reasonably recover from; `RuntimeException` for programming errors and unrecoverable conditions (Item 70). Don't add a checked exception where the caller can't act on it (Item 71).
- Favor the standard exceptions — `IllegalArgumentException`, `IllegalStateException`, `NullPointerException`, `IndexOutOfBoundsException`, `UnsupportedOperationException`, `ConcurrentModificationException` — over bespoke ones (Item 72).
- Throw an exception appropriate to the abstraction and chain the cause when translating (Item 73); include failure-capture detail in the message (Item 75); never ignore an exception with an empty `catch` (Item 77).

### Strong defaults

- Validate parameters at the top of public methods and fail fast (`Objects.requireNonNull(x, "x")`, range checks) — *Effective Java* Item 49.
- Strive for failure atomicity: a failed call leaves the object in its prior state (Item 76).
- Don't both log and rethrow the same exception at the same layer (double reporting); handle it or propagate it.

### Review questions

- Can the caller actually recover from this checked exception, or is it noise pushing `throws` through every layer?
- When an exception is translated, is the original cause chained?

## 4. Optional & null

### Hard rules

- `Optional` is a *return type* for a method whose empty result is a normal outcome (*Effective Java* Item 55; OpenJDK guidance, Stuart Marks). Never a field, parameter, collection element, or map value.
- Return an empty collection/array, never `null`, for an absent sequence (Item 54). Don't wrap a collection in `Optional`.
- Don't call `Optional.get()` without a presence check — use `.map`/`.filter`/`.orElse`/`.orElseGet`/`.orElseThrow`/`.ifPresent`. (Error Prone flags `OptionalGetWithoutIsPresent`.)
- Use `OptionalInt`/`OptionalLong`/`OptionalDouble` for primitives, not `Optional<Integer>`.

### Review questions

- Is `Optional` used anywhere other than a return type?
- Is a method returning `null` where an empty collection or an `Optional` return belongs?

## 5. Records, sealed types, enums & pattern matching

### Strong defaults

- Model immutable data as a `record` — it gives the canonical constructor, accessors, and correct `equals`/`hashCode`/`toString`. Reach for it before a hand-written value class or a Lombok `@Data`. Add a compact constructor for validation/normalization. (Goetz; modern *Effective Java* idiom.)
- Model a closed set of possibilities as a `sealed interface ... permits ...` over records (algebraic data types) and match it with an exhaustive `switch` — let the compiler enforce that every case is handled. (Goetz, *Data-Oriented Programming in Java*.)
- Use an `enum` instead of `int`/`String` constants (Item 34); enums can carry fields and behavior and give exhaustive `switch`.
- Prefer the enhanced `instanceof` pattern (`if (o instanceof User u)`) over instanceof-and-cast, and a `switch` *expression* with patterns over visitor boilerplate or `if/else if` chains.

### Review questions

- Is this a hand-written immutable value class (all-`final` fields, a constructor, manual `equals`/`hashCode`) that should be a `record`?
- Is a `switch` over a sealed type non-exhaustive, or padded with a `default` that hides a missing case?

## 6. Interfaces, abstract classes & inheritance

### Hard rules

- Prefer interfaces to abstract classes (*Effective Java* Item 20); use `default` methods for shared behavior and a skeletal implementation where it helps implementers.
- Favor composition over inheritance (Item 18); design and document for inheritance or prohibit it with `final` (Item 19).
- Refer to objects by their interfaces (Item 64): declare variables, fields, parameters, and returns as `List`/`Map`/`Collection`, not `ArrayList`/`HashMap`.

### Review questions

- Does this abstract class need to be a class, or would an interface with `default` methods be more flexible?
- Is a class extended across a package boundary where composition would be safer?

## 7. Method & constructor shape

### Strong defaults

- Static factory methods over constructors when a name clarifies, instances can be cached, or a subtype can be returned (*Effective Java* Item 1): `of`, `from`, `valueOf`, `getInstance`.
- Builder for many (especially optional) parameters (Item 2); for 1–3 required args a constructor or static factory is better than a builder.
- Prefer dependency injection — constructor injection — to hardwiring resources (Item 5). Constructor injection keeps fields `final`, makes dependencies explicit, and needs no container to test.
- Accept the most general useful type (`Collection`/`Iterable`/`List` over a concrete impl); return a useful contract (an unmodifiable `List`, never `null`).
- Make defensive copies of mutable parameters you store and mutable internals you return (Item 50).

## 8. Generics

### Hard rules

- Don't use raw types (`List` instead of `List<String>`) — Item 26.
- Eliminate unchecked warnings or suppress them narrowly with a comment justifying safety (Item 27).
- Prefer lists to arrays where covariance/erasure bites (Item 28); use bounded wildcards (PECS: producer-`extends`, consumer-`super`) to widen API flexibility (Item 31).

## 9. Streams & expressions

### Strong defaults

- Use streams *judiciously* (*Effective Java* Item 45): a stream for a clear, side-effect-free pipeline (`filter`/`map`/`collect`); a loop when there's local mutation, short-circuiting that fights the stream, checked exceptions, or when the loop is plainly clearer.
- Prefer side-effect-free functions in streams (Item 46); a stream whose work happens in a `forEach` side effect should be a loop.
- Prefer `Collection`/`Stream` return types appropriately (Item 47); use for-each over an index loop when the index isn't needed (Item 58).

## 10. Documentation

### Hard rules

- Public API members carry Javadoc (*Effective Java* Item 56): `@param`, `@return`, `@throws` for every parameter, return, and (checked or documented unchecked) exception.
- Document thread safety on every class (Item 82): immutable, thread-safe, conditionally thread-safe, or not thread-safe.

### Review questions

- Does a public method document its parameters, return, and the exceptions it throws?
- Does a class that will be shared across threads state its thread-safety level?
