# Type System & PHPStan Review Rules

PHP's runtime types are coarse. PHPStan/Psalm refined types in docblocks are the type system PHP lacks — they turn whole classes of bugs into static errors and document intent precisely. This file is the source of truth for the **Type System & Static Analysis** review lens.

Baseline assumption: this codebase targets **PHPStan level 9+** (and ideally `phpstan-strict-rules`). Calibrate severity to the project's configured level when it is lower (see *Severity calibration* at the end), but always *recommend* the precise-type vocabulary below.

The reviewer's job here is twofold: **flag real type-safety holes** (missing types, unnarrowed `mixed`, wrong nullability, structured data behind a bare `array`), and **flag missed opportunities** to use a more precise type that would make an illegal value unrepresentable.

---

## 1. Integer ranges

Use the narrowest integer type that the value actually permits. A count is never negative; an index into a non-empty list is `non-negative-int`; a quantity or an ID is usually `positive-int`.

| Type | Means | Flag when |
|---|---|---|
| `positive-int` | `> 0` | a quantity, page number, ID, or limit typed as bare `int` and guarded with `> 0` at runtime |
| `negative-int` | `< 0` | offsets/deltas constrained negative |
| `non-negative-int` | `>= 0` | a count, length, array index, or `count()`-derived value typed as `int` |
| `non-positive-int` | `<= 0` | the dual of `non-negative-int` |
| `non-zero-int` | `!= 0` | a divisor or step validated non-zero |
| `int<0, 100>` | inclusive range | a percentage, a score, a bounded dimension; also `int<min, 100>` / `int<50, max>` |

**Flag when:** a function validates a numeric bound at runtime (`if ($n <= 0) throw …`) but its signature still says `int`. Push the constraint into the type: `function setQuantity(positive-int $q)`. PHPStan then rejects callers that could pass `0` or a negative.

```php
// Suggestion: the guard belongs in the type
/** @param positive-int $perPage */
public function paginate(int $perPage): Page { … }
```

---

## 2. String types

| Type | Means | Flag when |
|---|---|---|
| `non-empty-string` | length ≥ 1 | a name/id/key/path typed `string` but never legitimately empty; especially return types and value-object inputs |
| `non-falsy-string` / `truthy-string` | non-empty and not `'0'` | stricter than `non-empty-string` where `'0'` must also be excluded |
| `numeric-string` | passes `is_numeric()` | a string about to go through `(int)`/`(float)`/`bcmath`; document it `numeric-string` after validation |
| `class-string` | any FQCN string | a class name passed as a string |
| `class-string<T>` | FQCN of a subtype of `T` | factories, service locators, `instanceof`/`new $class` on a variable — type-safe instantiation |
| `interface-string` / `trait-string` / `enum-string` | the respective name strings | reflection-style APIs taking those names |
| `callable-string` | a callable function name | a string passed to `call_user_func`/`array_map` |
| `literal-string` | statically composed, not user-derived | SQL/shell/HTML built by string concatenation — require `literal-string` at the boundary to make injection unconstructable |
| `lowercase-string` | ASCII lowercase | normalized keys, slugs, lowercased identifiers |

**Flag when:** a method returns `string` for something that is never empty (an id, a rendered template, a serialized payload) — use `non-empty-string`. **Flag hard** a `class-string` opportunity: any `function make(string $class): object` that does `new $class()` should be `@param class-string<T> $class @return T`, so the call site is checked and the return type is inferred.

```php
/**
 * @template T of Model
 * @param class-string<T> $class
 * @return T
 */
public function make(string $class): Model { return new $class(); }
```

---

## 3. Arrays, lists & shapes

A bare `array` is the single biggest source of missed type precision. Almost every `array` should be one of: a `list<T>`, a generic `array<K, V>`, or an `array{...}` shape.

| Type | Means | Flag when |
|---|---|---|
| `list<T>` | sequential int keys from 0 | any array built with `$x[] = …` or returned from `array_values`/`array_map` |
| `non-empty-list<T>` | a list with ≥ 1 element | code that does `$items[0]` or `reset()`/`end()` assuming at least one element |
| `array<K, V>` | a map, possibly empty | a keyed collection typed bare `array` |
| `non-empty-array<K, V>` | a map with ≥ 1 element | the same, when emptiness is impossible/forbidden |
| `array{a: T, b?: U}` | a sealed shape with optional `b?` | **structured data passed as an associative array** — the canonical smell |
| `array{int, string}` | a positional tuple shape | a fixed-arity tuple returned as an array |
| `array{foo: T, ...<string, U>}` | an unsealed shape | a shape that also carries arbitrary extra keys |
| `key-of<T>` / `value-of<T>` | keys/values of a shape or const array | a parameter that must be a key of a known map or a backed enum's values |

**Flag when:** a method takes or returns an associative array describing a *thing* (`['id' => …, 'name' => …]`). Two correct fixes, in order of preference: introduce a **value object / DTO** (see `coding-practices.md` §3 — associative arrays as structured data are a hard rule), or, where an array is genuinely the right shape (a serialized boundary), pin it with an `array{...}` shape so callers are checked. A bare `array` return for structured data is **Blocking** here.

```php
// Blocking: structured data hidden in an untyped array
/** @return array{id: positive-int, name: non-empty-string, email?: string} */
public function toRecord(): array { … }
// Better still: return a DTO / value object.
```

`list<T>` vs `array<int, T>` is a single-syntax choice — prefer `list<T>` whenever keys are 0-based sequential. Flag a `list<T>` typed as `array<int, T>` (and vice-versa when keys are not sequential).

---

## 4. Generics (`@template`)

Generics let one class/function be reused without losing type information. Reach for them on collections, repositories, factories, result/option wrappers, and mappers.

```php
/**
 * @template T of AggregateRoot
 */
interface Repository
{
    /** @return T|null */
    public function find(Identifier $id): ?AggregateRoot;

    /** @param T $aggregate */
    public function save(AggregateRoot $aggregate): void;
}

/** @extends Repository<Order> */
interface OrderRepository extends Repository { … }
```

- `@template T` — invariant type parameter (default).
- `@template-covariant T` — output-only (safe in return positions, e.g. an immutable read-only collection).
- `@template-contravariant T` — input-only.
- `@extends Foo<X>` / `@implements Foo<X>` / `@use Trait<X>` — bind a parent/interface/trait's type parameter from a concrete class.
- Bound a parameter with `@template T of SomeType`.

**Flag when:** a base `Repository`/`Collection`/factory returns the base type (`AggregateRoot|null`) and every subclass re-declares the same method only to narrow the return — that is exactly what a generic erases. Also flag a collection class whose `@var array` element type is undocumented (`@var list<Order>` at minimum).

---

## 5. Literals, enums & special return types

| Type | Means | Flag when |
|---|---|---|
| `'a'\|'b'\|'c'` | union of string literals | a `string` parameter that only accepts a fixed set — prefer a **backed enum**, but a literal union is the minimum |
| `0\|1\|2`, `Foo::BAR` | int / class-constant literals | a flag or mode argument |
| `true` / `false` | literal-boolean types | a method that provably returns only one, or with `@phpstan-assert-if-true` |
| `never` | never returns (throws/exits) | a method that always throws or `exit()`s but is typed `void` — use the native `never` return type (PHP 8.1) |
| `$this` | returns the same instance | fluent mutators on a non-final class — narrower than `static` |
| `static` | returns the late-bound type | named constructors / `with*()` on a base class so subclasses keep their type |
| `($cond is true ? A : B)` | conditional return | a method whose return type depends on a boolean/literal argument |
| `int-mask<A, B>` / `int-mask-of<T>` | bitmask of given flags | a `$flags` parameter combining `FLAG_*` constants |

**Flag when:** a `string`/`int` parameter accepts only a closed set of values — recommend a backed enum (see `modern-php.md`), or at minimum a literal union so PHPStan rejects out-of-set values. **Flag** a `void` method that always throws: it should be `never`.

---

## 6. Type aliases & assertions

**Aliases** keep a complex repeated type readable and single-sourced:

```php
/**
 * @phpstan-type UserRow array{id: positive-int, name: non-empty-string, roles: list<non-empty-string>}
 */
final class UserReadModel
{
    /** @return UserRow */
    public function toRow(): array { … }
}

/**
 * @phpstan-import-type UserRow from UserReadModel
 */
```

**Assertions** teach the analyzer what a guard/helper proves, so callers get narrowing without re-checking:

- `@phpstan-assert non-empty-string $value` — on a guard method that throws unless the condition holds.
- `@phpstan-assert-if-true T $value` / `@phpstan-assert-if-false null $value` — on a predicate returning `bool`.
- `@param-out T $ref` — on a by-reference parameter whose type changes after the call.

**Flag when:** a project uses a custom `Assert::`/`TypeUtils::ensure*` guard whose signature doesn't carry `@phpstan-assert`, so every call site still needs an `assert()`/`@var` to narrow. Adding the annotation removes the downstream casts. Also flag `@var` used as a substitute for a real check (see `coding-practices.md` §4) — prefer an assertion helper that narrows for real.

---

## 7. `mixed`, nullability & missing types

- **Missing types are findings.** At level 6+ PHPStan requires explicit types; a missing parameter/return/property type (no native type *and* no PHPDoc) is **Blocking** at this baseline.
- **`mixed` is a last resort.** Implicit `mixed` (level 10) is a hole; explicit `mixed` (level 9) should be narrowed to a union, a generic `@template`, or a precise shape wherever the value's possibilities are known. Flag `mixed` that flows from a typed source unnarrowed.
- **Nullability must be exact.** `?T` / `T|null` only where `null` is a real, expected value. Flag a `?T` that is never null in practice (drop the `?`) and a `T` that can be null (add it) — at level 8 PHPStan checks method/property access on nullable types, so a wrong `?` is a latent `TypeError`. Doctrine column/relation nullability must match the PHP type (see `coding-practices.md` §9).
- **No bare `array` / `iterable` for structured returns** — see §3 and `coding-practices.md` §3 (`iterable` return is a hard rule violation there).

---

## PHPStan rule levels (orientation)

| Level | Adds (cumulative) |
|---|---|
| 0–1 | unknown classes/methods/functions, undefined variables |
| 2 | method/property access on all expressions; PHPDoc validity |
| 3 | return types, property assignment types |
| 4 | dead code, always-false `instanceof`, unreachable branches |
| 5 | argument types passed to calls |
| 6 | **missing type hints required** (no implicit `mixed`) |
| 7 | partial-union errors (calling a method present on only some members) |
| 8 | calling methods / accessing properties on **nullable** types |
| 9 | strict explicit `mixed` (only assignable to `mixed`) |
| 10 | implicit `mixed` is an error |
| `phpstan-strict-rules` | extra rules on top: strict comparisons, no loose `switch`, booleans in conditions, etc. |

If the repo's `phpstan.neon*` sets a level below 8, say so in the finding and frame the deeper-type recommendations against where it could realistically move.

---

## Severity calibration for this lens

**Blocking** (real type-safety holes):
- missing parameter/return/property type with no PHPDoc (at level 6+ baseline)
- structured data passed/returned as a bare associative `array` (no shape, no DTO)
- `iterable` as a return type (hard rule, `coding-practices.md` §3)
- wrong nullability that allows a real `TypeError`/null-access on a reachable path
- unnarrowed `mixed` flowing into code that calls methods on it
- a `class-string`/`new $var` pattern with no `class-string<T>` constraint, so an arbitrary class can be instantiated

**Suggestion** (missed precision — the value would be safer/clearer with a refined type):
- `int` where `positive-int`/`non-negative-int`/`int<a,b>` is provable
- `string` where `non-empty-string`/`literal-string`/`class-string<T>` fits
- `array`/`array<int,T>` where `list<T>`/`non-empty-list<T>`/an `array{...}` shape fits
- a base-type return that a `@template` generic would make precise across subclasses
- a closed-set `string`/`int` argument that should be an enum or a literal union
- a `void` method that always throws → `never`
- a custom guard helper missing `@phpstan-assert`
- a repeated complex inline type that should be a `@phpstan-type` alias

**Nit**:
- `list<T>` vs `array<int, T>` mismatch where keys are 0-based
- `$this` vs `static` choice on a fluent return
- docblock type formatting / ordering

Anchor each finding in the concrete type to use and, when it helps, the one-line docblock. Don't restate a type error PHPStan already emits — cite it and point at the fix.
