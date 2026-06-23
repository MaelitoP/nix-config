# Example Review Comments (Java)

Use these as a tone and quality reference. Terse, concrete, with an idiomatic fix.

## Good example — Reachable NPE via unboxing (blocking)

- **File:** `src/main/java/billing/Ledger.java:42`
- **Title:** Auto-unboxing a possibly-`null` map value throws `NullPointerException`
- **Why it matters:** `int balance = balances.get(accountId);` unboxes the `Integer` returned by `Map.get`, which is `null` for an unknown account — normal input, not an invariant. The NPE is thrown at the unbox, far from the real cause. (SpotBugs `NP_UNBOXING_NULL`.)
- **Recommendation:** Keep it boxed and handle absence explicitly:
  ```java
  Integer balance = balances.get(accountId);
  if (balance == null) {
      throw new UnknownAccountException(accountId);
  }
  ```
- **Confidence:** high

## Good example — Resource leak (blocking)

- **File:** `src/main/java/io/Importer.java:31`
- **Title:** `InputStream` leaks when parsing throws
- **Why it matters:** `InputStream in = Files.newInputStream(path); return parse(in);` never closes `in` if `parse` throws — the file handle leaks under any parse error. (Error Prone `StreamResourceLeak`.)
- **Recommendation:** Use try-with-resources so it closes on every path:
  ```java
  try (InputStream in = Files.newInputStream(path)) {
      return parse(in);
  }
  ```
- **Confidence:** high

## Good example — Data race (blocking)

- **File:** `src/main/java/cache/Counter.java:18`
- **Title:** Shared `count` is read/written by multiple threads without synchronization
- **Why it matters:** `private int count;` is incremented from worker threads and read from the reporting thread with no `synchronized`/`volatile`/atomic. `count++` is a read-modify-write (not atomic), and without a `happens-before` edge the reporting thread may never see updates at all — this is a memory-model guarantee that isn't there, not a timing window. (*Effective Java* Item 78; *JCiP*.)
- **Recommendation:** Use an atomic:
  ```java
  private final AtomicLong count = new AtomicLong();
  // count.incrementAndGet();  ... count.get();
  ```
- **Confidence:** high

## Good example — equals without hashCode (blocking)

- **File:** `src/main/java/model/Money.java:55`
- **Title:** `equals` overridden without `hashCode` breaks hash-based collections
- **Why it matters:** Two equal `Money` objects now return different `hashCode`s, so a `HashSet`/`HashMap` will treat them as distinct — lookups silently miss. The `equals`/`hashCode` contract requires both, over the same fields. (*Effective Java* Item 10–11; Error Prone `EqualsHashCode`.)
- **Recommendation:** This is an immutable value — make it a `record` and delete both hand-written methods:
  ```java
  public record Money(long amountMinor, Currency currency) {}
  ```
- **Confidence:** high

## Good example — Optional misuse & null return (suggestion)

- **File:** `src/main/java/user/UserService.java:27`
- **Title:** Method returns `null` for "not found" and stores an `Optional` field
- **Why it matters:** `User find(id)` returning `null` forces every caller to null-check and invites NPEs; and `private Optional<Address> address;` uses `Optional` as a field, which it isn't meant for (extra wrapping, not serializable-friendly). `Optional` is a *return type* for absent results (*Effective Java* Item 55; OpenJDK guidance).
- **Recommendation:** Return `Optional<User>` from the lookup; keep the field a plain nullable `Address` (or model presence with the type), and expose `Optional<Address> address()`:
  ```java
  public Optional<User> find(UserId id) { ... }
  ```
- **Confidence:** high

## Good example — Idiom & naming (suggestion)

- **File:** `src/main/java/parse/TokenUtils.java:12`
- **Title:** `instanceof`-and-cast and a `Utils` junk-drawer class
- **Why it matters:** `if (n instanceof NumberNode) { NumberNode num = (NumberNode) n; … }` is the pre-16 idiom; the enhanced `instanceof` pattern is canonical. And `TokenUtils` is a bag of unrelated statics — a cohesion smell; the methods belong on the token types.
- **Recommendation:** `if (n instanceof NumberNode num) { … num.value() … }`; move each static onto the `Token`/`Node` type it operates on and delete `TokenUtils`.
- **Confidence:** high

## Good example — Consistency clearly labeled (suggestion)

- **File:** `src/main/java/route/Dispatcher.java:21,47`
- **Title:** File uses a fall-through `switch` statement and a `switch` expression for the same shape
- **Why it matters:** Line 21 assigns a variable via a `case ...: x = ...; break;` statement; line 47 uses the arrow `switch` expression for an equivalent mapping. The variety is noise, and the statement form risks fall-through/missing-case bugs the expression form rules out.
- **Recommendation:** Use the `switch` expression in both (canonical in `consistency.md`), letting the compiler enforce exhaustiveness:
  ```java
  var handler = switch (kind) {
      case GET -> getHandler;
      case POST -> postHandler;
  };
  ```
  Strong default, not a hard rule.
- **Confidence:** medium

## Good example — Design question handed off

- **File:** `src/main/java/pricing/PricingStrategy.java:8`
- **Title:** `PricingStrategy` interface may be premature abstraction
- **Why it matters:** The interface has one implementation and one caller; the indirection adds a layer without a second strategy in sight.
- **Recommendation:** Use the concrete type for now; introduce the interface when a second pricing model actually lands.
- **Confidence:** medium
- → `/java-expert Should pricing variation be an interface now, a sealed hierarchy of records, or deferred until a second model exists?`

## Bad example

> Naming could be better and you should probably handle that exception.

Why this is bad:
- no file/line
- no explanation of impact
- no concrete idiomatic fix
- no severity, no confidence
