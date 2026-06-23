# Single-Syntax Consistency Rules

This is the "one way to do things" doc. Java's surface is wide — there are usually several ways to spell the same intent — so a formatter (`google-java-format` / Spotless) removes layout debates and this file extends that uniformity to the choices the formatter leaves open. When the same thing can be written two ways, **pick the canonical form below** and flag deviations. The goal is to remove noise so readers spend attention on logic, not on incidental variety.

These are **opinionated strong defaults**, not hard language rules. Flag a deviation as a `Suggestion` and name the canonical form. Allow a deviation only when there is a concrete local reason, and say so. Some of these are also Error Prone / PMD checks — when a tool already flags it, cite the check instead of restating it.

## How to apply

For each rule: the canonical form is on the left, the discouraged variant on the right. A diff that introduces the discouraged form — or a file that uses both forms for the same purpose — is a finding. Mixing forms within one file is worse than either form used consistently; call that out specifically.

## 1. Type testing & casting

| Canonical | Avoid |
|---|---|
| `if (o instanceof User u) { … u.name() … }` (pattern) | `if (o instanceof User) { User u = (User) o; … }` |
| `switch` expression with patterns over a sealed type | an `if/else if` chain of `instanceof` casts |

## 2. switch

| Canonical | Avoid |
|---|---|
| `switch` *expression* (arrow `->`, returns a value, exhaustive) | a fall-through `switch` *statement* assigning a variable |
| exhaustive `switch` over an enum/sealed type (no `default`) | a `default:` that silently swallows an unhandled new case |

- Use the arrow form; let the compiler check exhaustiveness over enums and sealed types. Add a `default` only for a genuinely open domain, not to dodge exhaustiveness.

## 3. Local variable type — `var`

- Use `var` when the initializer makes the type obvious and removes redundant repetition: `var users = new ArrayList<User>();`, `var entry = iterator.next();`. (OpenJDK *LVTI Style Guidelines*.)
- Don't use `var` when it hides a non-obvious type, when the RHS is a literal whose type matters (`var x = 0;` vs a needed `long`), or to capture a diamond `<>` you'd otherwise spell out. Never on fields, parameters, or returns.
- Pick one posture per file: don't alternate `var` and the explicit type for the same kind of declaration.

## 4. Collection & value construction

| Canonical | Avoid |
|---|---|
| `List.of(a, b, c)` / `Map.of(k, v)` / `Set.of(...)` (immutable) | `Arrays.asList(...)` then treating it as immutable; `new ArrayList<>(){{ add(...); }}` double-brace |
| `new ArrayList<>()` (diamond) | `new ArrayList<String>()` repeating the type |
| `Collections.emptyList()` / `List.of()` for empty returns | returning `null` for an absent collection |
| `Map.entry(k, v)` / `Stream`+`Collectors.toMap` for built maps | repeated `put` for a fixed literal map |

## 5. Equality & comparison

- `equals` for object/`String`/boxed comparison; `==` only for primitives and reference identity. (`==` on `String`/`Integer` is an Error Prone/SpotBugs finding.)
- `Objects.equals(a, b)` for null-safe equality; `Objects.hash(...)` for `hashCode`.
- Build comparators with `Comparator.comparing(...).thenComparing(...)`, not hand-rolled `a - b` subtraction (overflow) or nested `if`.
- `BigDecimal`: compare with `compareTo` (value), not `equals` (which also compares scale).

## 6. Null handling

- `Objects.requireNonNull(x, "x")` at the top of a method for a required reference, not a hand-written `if (x == null) throw`.
- `Optional` only as a return type; `Optional.orElse`/`orElseGet`/`orElseThrow`/`map`, never `.get()` without a check.
- Return an empty collection, not `null`. Don't return `Optional<Collection>`.

## 7. Strings

- Text block (`"""…"""`) for multi-line/embedded-quote strings, not `"\n"`-concatenation.
- `String.format`/`formatted`, or `+` for a couple of operands; `StringBuilder` in a loop (don't `+=` a `String` in a loop — PMD/Error Prone flag it).
- `String.join`/`Collectors.joining` to join, not a manual delimiter-and-trailing-separator loop.
- `str.isEmpty()` / `str.isBlank()`, not `str.length() == 0` / `str.trim().isEmpty()`.

## 8. Streams vs loops

- A stream for a clear, side-effect-free transform; a `for`/for-each loop when there's local mutation, early exit, or a checked exception. Don't write a stream whose body is a side-effecting `forEach` — that's a loop in disguise (*Effective Java* Item 46).
- Pick one within a method: don't half-convert a loop to a stream and leave the rest imperative for the same data.
- `for-each` over an index loop when the index is unused; `IntStream.range`/an index loop when you need the index.

## 9. Resource management

- try-with-resources for every `AutoCloseable`, not try/finally with a manual `close()` (Error Prone/SpotBugs flag the leak). Declare multiple resources in one try; they close in reverse order.

## 10. Imports & layout

- Let the formatter group and order imports. No wildcard imports (`import java.util.*;`) — the *Google Java Style Guide* forbids them, static or otherwise.
- Don't fight the formatter on braces, wrapping, or indentation; if a file isn't formatter-clean, the finding is "run the formatter", not per-line nits.

## 11. Annotations & boilerplate

- `@Override` on every overriding/implementing method (*Effective Java* Item 40); its absence on an override is a finding.
- `@FunctionalInterface` on an interface intended as a lambda target.
- Prefer a `record` or the standard library to a hand-written getter/`equals`/`hashCode`/builder where it applies; don't hand-roll what `record`/`java.util` already gives you.

## Review wording

When you flag a consistency issue, say:
- which canonical form applies,
- that it is a strong default (not a hard rule), and the Error Prone/PMD check name if one exists,
- and whether the file mixes forms (mixing is the stronger finding).

Example: "Suggestion — this tests type then casts (`(User) o`) at line 30 where the `instanceof` pattern is canonical: `if (o instanceof User u)`. The file already uses the pattern form at line 52; mixing the two is the noise. Strong default, not a hard rule."
