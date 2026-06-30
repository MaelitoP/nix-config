# PHP Philosophy & Principles

The principles that ground every recommendation. Sources: Matthias Noback (*Object Design Style Guide*, *Advanced Web Application Architecture*, his DDD/hexagonal writing), Vaughn Vernon (*Implementing Domain-Driven Design*, *Effective Aggregate Design*), Eric Evans (*Domain-Driven Design*), Marco Pivetta / Ocramius (immutability, "never getter/setter your entities"), Brent Roose (stitcher.io — modern PHP, never-null, value objects), the PHP-FIG standards (PSR-1/4/11/12/20), the Symfony best practices, and the PHPStan / Psalm type-system documentation. Cite these by name when advising.

## The overriding value: push correctness into the type system, and prefer immutability

- **Encode constraints in types, not in runtime checks scattered across the codebase.** A `non-empty-string`, a `positive-int`, a `PostId` value object, or a backed enum makes an illegal value unconstructable. PHP's type system is weak by default; PHPStan/Psalm generics and refined types (`positive-int`, `non-empty-list<T>`, `class-string<T>`, array shapes) are the language extension that buys back compile-time safety. Run PHPStan at a high level (9+) and treat its findings as the spec. (PHPStan docs; Noback, *Object Design Style Guide* §3.)
- **`declare(strict_types=1)` in every file.** Without it, PHP coerces `"5"` to `5` and hides bugs. Strict types make a type error a type error.
- **Prefer immutable objects.** Construct an object whole and valid, then never mutate it; "change" returns a new instance (`withX()`). Immutable objects are simple, freely shareable, and impossible to leave half-built. (Noback §3.1; Ocramius, "immutable objects".)
- **Make illegal states unrepresentable.** A value object validates in its constructor and can only exist in a valid state; a backed `enum` makes a closed set of options exhaustive; a `match` over it is statically checkable. Validate at the boundary (value-object constructor, application service) and the invalid case never propagates inward.

## Program to interfaces — ports and adapters

- **Depend on abstractions only where the dependency crosses the application boundary.** Repositories, clients for external systems, and other I/O are *ports*: the domain/application layer defines the interface, the infrastructure layer provides the adapter. Everything else (entities, value objects, application services, controllers) is specific and need not hide behind an interface — don't add a one-implementation interface "for testability". (Noback, *Object Design Style Guide* ch. 8–9; hexagonal architecture.)
- **Dependencies flow inward only.** Infrastructure → Application → Domain. The domain layer knows nothing about Doctrine, HTTP, GraphQL, the message bus, or the framework. This is what makes the domain testable without a database and the infrastructure replaceable.
- **Inject dependencies through the constructor, require all of them.** No optional dependencies (use a Null Object), no service locator, no setter injection. A constructed service is a complete, immutable object graph. Constructors only validate and assign — no work, no side effects. (Noback §1.)

## Composition over inheritance

- **Favor composition; do not inherit to reuse code.** Inheritance couples a subclass to a superclass's internals and is fragile across changes. Delegate to a collaborator instead. Inherit only for a genuine type relationship you fully control. (Noback, *Object Design Style Guide* §7.)
- **`final` by default.** Mark classes `final` unless they are explicitly designed for extension. `final` keeps the public API small and forces composition. (Ocramius, "when to declare classes final".)
- **`private` by default; `public` only when it is part of the contract.** Use `public` or `private` — `protected` exists to support inheritance you should not be doing.

## Exceptions are values you design, not control flow

- **Throw for failures; never return `null`/`false` to signal an error.** A query that can legitimately find nothing returns an empty collection, a Null Object, or throws a named exception — never a `User|false` union the caller forgets to check. (Noback §5.2; Roose, "don't return null".)
- **Domain exceptions are named after the broken rule.** `CouldNotFindProduct`, `OrderAlreadyShipped` — built with named constructors (`CouldNotFindProduct::withId($id)`). Distinguish *domain* exceptions (a business rule broke), *infrastructure* exceptions (a database/HTTP call failed), and *logic* exceptions (`InvalidArgumentException`, `LogicException` — a programming bug).
- **Don't swallow.** Never catch `\Throwable`/`\Error`; after catching, either log or rethrow, never both; never `return` in `finally`; never leak a raw exception message to a user.

## Modern PHP is a design tool (8.1 → 8.4)

- **Value objects with `readonly`.** `readonly` properties (8.1) and `readonly class` (8.2) express immutability in the language, not just by convention. Combine with constructor property promotion to remove the boilerplate.
- **Enums replace magic constants.** A backed `enum` (8.1) for a closed set of values; add behavior with methods and `match`. A pure enum for a set of cases with no scalar backing. Never a bare `const FOO = 'foo'` where an enum fits. (*Effective*-style: avoid strings/ints where a type fits.)
- **`match` over `switch`** for exhaustive value mapping — it is an expression, strict (`===`), and throws on an unhandled case instead of falling through.
- **`never` return type** for a method that always throws or exits — it tells both the reader and the analyzer that control does not return.
- **First-class callable syntax (`$fn = strlen(...)`)**, **named arguments** for many-parameter or optional-flag calls, and **property hooks + asymmetric visibility** (8.4) where they remove a getter/setter pair — use them when they make intent clearer, not for novelty.

## Domain-Driven Design & Hexagonal architecture

- **Value objects wrap primitives and attract behavior.** A `Title`, `EmailAddress`, or `Money` validates once, compares by value, and is the natural home for related operations. Extract one whenever a primitive is validated in more than one place. (Noback §2.3; Evans.)
- **Entities expose business actions, not setters.** Named constructors create them; imperative command methods change them; they record domain events; they reference other aggregates *by identity*, never by object reference. (See `../php-review/ddd.md` for the project's hard rules — they override textbook defaults.)
- **Design small aggregates.** An aggregate is a transactional-consistency boundary, not an object graph. Keep it to a root plus the minimum it must hold consistent; modify one aggregate per transaction. (Vernon, *Effective Aggregate Design* — "model true invariants in consistency boundaries", "design small aggregates", "reference other aggregates by identity".)
- **Eventual consistency outside the boundary.** A rule that spans aggregates is resolved by a domain event and an event handler, not by one command handler touching two roots. Ask: "is it this user's job to make it consistent now?" If not, make it eventually consistent. (Vernon; Evans.)
- **Application services are thin.** One method = one use case: translate primitives to value objects, call exactly one method on one aggregate, persist, dispatch events. No business logic, no infrastructure code. (Noback ch. 9.)

## Tooling is part of the language

- **PHPStan/Psalm end type debates.** A high-level static analysis run is the type checker PHP lacks at runtime. Generics and refined types in docblocks are real types to the analyzer — use them (`@template`, `list<T>`, `array{...}`, `positive-int`). A reported error is a finding, not noise. (PHPStan rule levels; see `../php-review/types.md`.)
- **The formatter ends formatting debates.** PHP-CS-Fixer / PHP_CodeSniffer against PSR-12 makes all PHP in a repo read the same way. Never hand-fight it.
- **Rector automates upgrades.** Use it to mechanically modernize to current PHP syntax rather than hand-editing.
- **Tests lock in behavior.** PHPUnit for units, behavioral tests for the domain; fakes/stubs for queries, mocks/spies only to verify commands; no `sleep()` as synchronization. (Noback §6.7; see `../php-review/testing.md`.)

## Precedents to cite

These usually end a debate — point at the canon:

- Immutable value types: `DateTimeImmutable`, backed `enum`s, `Symfony\Component\Uid\Uuid`, money/quantity value objects.
- Ports & adapters: a domain `interface OrderRepository` with an infrastructure `DoctrineOrmOrderRepository implements OrderRepository`.
- Named constructors over `new`: `DateTimeImmutable::createFromFormat`, `Uuid::v4`, `Money::fromAmount`, exceptions via `CouldNotFindProduct::withId`.
- Closed sets as enums: `enum OrderStatus: string { case Pending = 'pending'; … }` matched by an exhaustive `match`.
- Refined types as the spec: `positive-int`, `non-empty-string`, `non-empty-list<T>`, `class-string<T>`, `array{id: int, name: non-empty-string}` (PHPStan).
- DDD rules as canon: Vernon's *Effective Aggregate Design* rules, and the project's `../php-review/ddd.md`.
