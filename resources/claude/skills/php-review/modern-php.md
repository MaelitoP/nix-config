# Modern PHP Review Rules (8.1 → 8.4)

Industry-accepted modern-PHP practices, framed as reviewer rules. Sources: Matthias Noback (*Object Design Style Guide*), Marco Pivetta / Ocramius (immutability, `final`), Brent Roose / stitcher.io (modern PHP, never-null), the PHP-FIG PSRs, and the Symfony best practices. These complement `coding-practices.md` (project conventions) and `types.md` (the type system); where they overlap, those files win on project-specific rules.

The point of modern PHP is not novelty — it's that `readonly`, enums, `match`, and `never` let you encode design decisions the language used to leave to convention. Recommend a feature when it makes intent clearer or an illegal state unconstructable, not for its own sake. Version-gate suggestions to the project's actual PHP version (check `composer.json` `require.php`).

## 1. Strictness

### Hard rules
- Every PHP file declares `declare(strict_types=1);`. A new file without it is **Blocking** — strict types are what make a type mismatch fail instead of silently coercing.
- Every parameter, return, and property has a native type (plus a PHPDoc refinement where `types.md` calls for one). Untyped is **Blocking** at our PHPStan baseline.

### Flag when
- A new file is missing `declare(strict_types=1)`.
- A signature relies on coercion (`function f(int $x)` called with a `"5"` string upstream) instead of converting explicitly at the boundary.

## 2. Immutability & value objects

### Strong defaults
- Value objects and DTOs are immutable: `readonly` promoted properties (8.1), or a `readonly class` (8.2) for a type that is *entirely* immutable. No setters; "change" returns a new instance.
- Use constructor property promotion for the common "assign each argument to a property" constructor.

### Flag when
- A value object / DTO has mutable public properties or setters → **Suggestion** (Blocking if a shared value object is mutated in place and that causes aliasing bugs). Recommend `readonly`.
- A pure value/DTO class in an 8.2+ project declares each property `readonly` individually where `readonly class` would say it once → **Nit/Suggestion**.
- A hand-written constructor that just assigns each argument to a same-named property → **Suggestion**: use promotion.
- `clone` is used to "modify" a `readonly` object by reassigning a property afterwards (illegal on readonly) — point at PHP 8.3 `clone with`-style copy or a `with*()` method.

## 3. Enums over magic constants

### Strong defaults
- A closed set of values is a backed `enum` (8.1), not a group of `const` strings/ints or a class with constants. Attach behavior with methods and `match`.
- A set of cases with no scalar backing is a pure enum.

### Flag when
- A `string`/`int` parameter accepts only a fixed set (status, type, mode) and is validated by hand or by a constant list → **Suggestion**: introduce a backed enum (and see `types.md` §5 for the literal-union fallback). Enums make invalid values unconstructable and `match` over them statically checkable.
- A `switch`/`if` ladder maps a constant to behavior that the enum could own as a method.

## 4. `match`, `never`, and control flow

### Strong defaults
- `match` over `switch` for value mapping: it is an expression, compares with `===`, and throws `UnhandledMatchError` instead of silently falling through. (See `coding-practices.md` §5 on exhaustiveness — don't add a catch-all `default` where exhaustiveness should be enforced.)
- `never` return type (8.1) for a function that always throws or exits.

### Flag when
- A `switch` used purely to assign a value from a finite set → **Suggestion**: `match`.
- A `match`/`switch` with a `default` arm that hides a non-exhaustive set the type system could enforce → cross-reference `coding-practices.md` §5.
- A method that always throws (a guard/factory-failure helper) typed `void`/no return → **Suggestion**: `never`.

## 5. Errors as exceptions, not null/false

### Hard rules
- Don't signal an error with `null`/`false`. Throw a named domain exception, or return a single type (empty collection / Null Object) when "nothing" is a legitimate outcome. A `T|false` return is **Blocking** (see `types.md`, `php-expert` philosophy).
- Domain exceptions extend a domain base and are built with named constructors (`CouldNotFindOrder::withId($id)`). Distinguish domain vs infrastructure vs `LogicException`/`InvalidArgumentException` (programmer error).

### Flag when
- A query returns `Foo|null`/`Foo|false` where the absence is actually an error the caller can't sensibly handle → **Suggestion/Blocking**: throw.
- A bespoke exception duplicates a standard one for a pure programming error → prefer `InvalidArgumentException`/`LogicException`.

## 6. Object construction & API ergonomics

### Strong defaults
- Named constructors for domain objects (`Order::place(...)`), private `__construct` enforcing invariants. (Noback; `coding-practices.md`.)
- Named arguments at call sites with several optional/boolean parameters, to make the call self-documenting — and as the reason a boolean argument is at least readable; the deeper fix is still separate methods (`coding-practices.md` §5).
- First-class callable syntax (`strlen(...)`, `$this->handle(...)`) over string callables (`'strlen'`, `[$this, 'handle']`).

### Flag when
- A public constructor with multiple creation paths or a half-validated object → **Suggestion**: named constructors.
- A string/array callable where first-class callable syntax is clearer and statically checkable → **Nit/Suggestion**.

## 7. PHP 8.4 features (version-gated)

### Suggestions only, and only on 8.4+ projects
- **Property hooks**: replace a private property + a trivial getter/setter pair with a hooked property when it removes boilerplate and the validation/derivation reads more clearly. Don't push behavior-heavy logic into hooks.
- **Asymmetric visibility** (`public private(set) Type $x`): for a value that should be publicly readable but only mutated internally — a lighter alternative to a getter, while keeping write access closed.

### Flag when
- A class on 8.4 has a forest of one-line getters over private fields → **Suggestion**: property hooks or asymmetric visibility, where it doesn't fight immutability (`readonly` is still preferred for true value objects).

Do not raise 8.4 suggestions on a project pinned below 8.4.
