# Style Guide for Object Design — Part 2: Using Objects
*Matthias Noback — © 2018*

Covers: Ch 3 (Manipulating Objects), Ch 4 (Method Template), Ch 5 (Retrieving Information), Ch 6 (Performing Tasks)

---

## 3. Manipulating Objects

### 3.1 Prefer Immutable Objects

Mutable shared state leads to surprising bugs. Design nearly all objects to be immutable. When a change is needed, create a new instance.

```php
// Mutable DateTime causes a bug:
public function reminderTime(): string
{
    return $this->time->modify('-1 hour')->format('h:s');
    // BUG: modify() changes $this->time in place (DateTime is mutable)
}

// Solution: use immutable objects (DateTimeImmutable), or model immutability yourself
final class Year
{
    public function __construct(private int $year) {}

    public function next(): Year
    {
        return new self($this->year + 1); // returns a new instance
    }
}

$year = new Year(2018);
$year = $year->next(); // assign the result; $year is now 2019
```

### 3.2 A Modifier on an Immutable Object Should Return a Modified Copy

Two patterns for returning a modified copy:

```php
// Pattern 1: pass new value to constructor
public function plus(Integer $other): Integer
{
    return new self($this->integer + $other->integer);
}

// Pattern 2: clone and modify (useful for multi-property objects)
public function withX(int $x): Position
{
    $copy = clone $this;
    $copy->x = $x;
    return $copy;
}
```

Prefer domain-meaningful, higher-level modifier names over generic setters:

```php
// Instead of: $position->withX($position->x() - 4)
$position->toTheLeft(4);
```

### 3.3 Modifier Methods on Immutable Objects Should Have Declarative Names

Use declarative (not imperative) names. Template: *"I want this …, but …"*

| Imperative (avoid) | Declarative (prefer) |
|---|---|
| `moveLeft(int $steps)` | `toTheLeft(int $steps)` |
| `multiplyBy(int $n)` | `multipliedBy(int $n)` |
| `addHeader(string $h)` | `withHeader(string $h)` |

### 3.4 Compare Whole Objects

With immutable objects, avoid testing via getters. Compare the whole object instead:

```php
// Avoid: adds unnecessary getter to test internals
assertSame(6, $nextPosition->x());

// Prefer: compare whole objects
assertEquals(new Position(6, 20), $nextPosition);
```

### 3.5 When Comparing Immutable Objects, Assert Equality, Not Sameness

Always use `assertEquals()` (value equality), not `assertSame()` (reference identity) for immutable objects. For production code, implement an `equals()` method:

```php
public function equals(Position $other): bool
{
    return $this->x === $other->x && $this->y === $other->y;
}
```

### 3.6 Calling a Modifier Method Should Always Result in a Valid Object

Modifier methods must enforce the same domain invariants as constructors:

```php
public function add(int $distance): CumulativeDistance
{
    Assertion::greaterOrEqualThan($distance, 0, 'You cannot add a negative distance');
    $copy = clone $this;
    $copy->cumulativeDistance += $distance;
    return $copy;
}
```

If the modifier delegates to the constructor, validation is reused automatically:

```php
public function withDenominator(int $newDenominator): Fraction
{
    return new self($this->numerator, $newDenominator); // constructor validates
}
```

### 3.7 On a Mutable Object, Modifier Methods Should Be Command Methods

Mutable objects (entities) have modifier methods with `void` return type — they change state, they do not return anything:

```php
final class Player
{
    public function moveLeft(int $steps): void
    {
        $this->position = $this->position->toTheLeft($steps);
    }
}
```

### 3.8 A Modifier Method Should Verify That the Requested State Change Is Valid

Protect against invalid state transitions. Throw a `LogicException` (or a custom `InvalidStateTransition`) when a transition is not permitted:

```php
public function cancel(): void
{
    if ($this->status->equals(Status::cancelled())) {
        return; // idempotent — ignore, don't throw
    }
    if ($this->status->equals(Status::delivered())) {
        throw new LogicException('A delivered order cannot be cancelled');
    }
    // ...
}
```

### 3.9 Use Internally Recorded Events to Verify Changes on Mutable Objects

Record domain events inside mutable objects instead of exposing getters just for testing:

```php
final class Player
{
    private array $events = [];

    public function moveLeft(int $steps): void
    {
        if ($steps === 0) return;
        $nextPosition = $this->position->toTheLeft($steps);
        $this->position = $nextPosition;
        $this->events[] = new PlayerMoved($nextPosition);
    }

    public function recordedEvents(): array
    {
        return $this->events;
    }
}

// Test
$player = new Player(new Position(10, 20));
$player->moveLeft(4);
assertContains(new PlayerMoved(new Position(6, 20)), $player->recordedEvents());
```

> **Note:** Use `assertContains()` rather than `assertEquals([...], $player->recordedEvents())` to keep tests resilient to other events recorded inside the object.

### 3.10 Don't Use Fluent Interfaces on Mutable Objects

Fluent interfaces (methods returning `$this`) on mutable objects are deceptive — they look like immutable modifiers but are not. This causes subtle bugs when clients assume intermediate states can be safely reused.

```php
// Deceptive: looks immutable, but where() mutates and returns $this
$qb->select()->from()->where()->orderBy();
```

If you want a fluent interface, make the object genuinely immutable.

### 3.11 Summary

- Prefer immutable objects for nearly everything. Return modified copies from modifier methods.
- Use declarative names for modifiers on immutable objects; use imperative (`void`) names for command methods on mutable objects.
- Always ensure modifier methods leave the object in a valid state.
- Use internally recorded events to verify changes on mutable objects — this avoids unnecessary getters.
- Never use fluent interfaces on mutable objects.

---

## Part II: Using Objects

---

## 4. A Template for Implementing Methods

Every method should follow this template:

```
[scope] function methodName(type $name, ...): void|[return-type]
{
    [pre-condition checks]   // validate arguments; throw InvalidArgumentException
    [failure scenarios]      // handle runtime failures; throw RuntimeException
    [happy path]             // do the work
    [post-condition checks]  // optional sanity checks on result
    [return value]           // only for query methods
}
```

### 4.1 Pre-condition Checks

Verify that provided arguments are correct before doing any work:

```php
Assertion::inArray($value, [...]);
Assertion::greaterThan($value, 0);
Assertion::allIsInstanceOf($listeners, EventListener::class);
```

> **Refactoring tip:** When pre-condition checks validate a primitive type argument, extract a value object and move the check into its constructor (the "Replace Primitive with Object" refactoring). This eliminates the need for the check in the method itself.

### 4.2 Failure Scenarios

Things that pass pre-condition checks can still fail at runtime. These get a `RuntimeException`:

```php
$record = $this->db->find($id);
if ($record === null) {
    throw new RuntimeException(sprintf('Could not find record with ID "%d"', $id));
}
```

### 4.3 Happy Path

The main task of the method — if kept small, this section is often very short.

### 4.4 Post-condition Checks

Rarely needed, but useful in legacy code or complex calculations:

```php
$result = ...;
Assertion::greaterThan(0, $result); // "this should never happen"
return $result;
```

> **Tip:** If you find yourself writing post-condition checks often, promote return types to proper objects so they can't exist in an invalid state.

### 4.5 Return Value

Only query methods return values. Return early as soon as you know the answer.

### 4.6 Some Rules for Exceptions

**Use custom exception classes when:**
1. You need to catch a specific type higher up.
2. There are multiple ways to instantiate the exception.
3. Named constructors improve the call site.

**Naming conventions:**

| Type | Pattern | Examples |
|---|---|---|
| Invalid argument / logic | `Invalid…` | `InvalidEmailAddress`, `InvalidStateTransition` |
| Runtime exception | Finish "Sorry, I…" | `CouldNotFindProduct`, `CouldNotStoreFile`, `CouldNotConnect` |

**Add detailed messages via named constructors:**

```php
// Bad: message assembled at call site
throw new CouldNotFindProduct(sprintf('Could not find product with ID "%s"', $id));

// Good: message assembled inside the exception class
throw CouldNotFindProduct::withId($productId);

final class CouldNotFindProduct extends RuntimeException
{
    public static function withId(ProductId $id): self
    {
        return new self(sprintf('Could not find a product with ID "%s"', $id));
    }
}
```

### 4.7 Summary

Methods follow a clear four-section template: pre-condition checks → failure scenarios → happy path → return value. Throw `InvalidArgumentException` or `LogicException` for bad input, `RuntimeException` for runtime failures. Use custom exception classes with named constructors to produce readable call sites.

---

## 5. Retrieving Information

### 5.1 Use Query Methods for Information Retrieval

A **query method** has a specific return type and produces **no side effects**. A **command method** has a `void` return type and produces side effects.

These two must be kept strictly separate (Command/Query Separation — CQS):

```php
// Command method: changes state, returns void
public function increment(): void
{
    $this->count++;
}

// Query method: no side effects, returns a value
public function currentCount(): int
{
    return $this->count;
}
```

For immutable objects, modifiers return a copy (not `void`), so they are not traditional query methods — but group them mentally with command methods since they produce a state change (on a new instance).

### 5.2 Query Methods Should Have Single-Type Return Values

Never return mixed types (`User|false`, `Page|null`). Choose one of:

- Return the type and **throw an exception** if not found.
- Return a **Null Object** if the empty case is legitimate.
- Return an **empty array/list** if zero results is valid.

```php
// Throw if not found
public function getById(int $id): User
{
    $user = ...;
    if (!$user instanceof User) {
        throw new UserNotFound(...);
    }
    return $user;
}

// Null Object
public function findOneBy(PageType $type): Page
{
    return $page instanceof Page ? $page : new EmptyPage();
}
```

> **Convention:** Methods starting with `get` either return the thing or throw. Methods starting with `find` return the thing or an empty alternative.

### 5.3 Avoid Query Methods That Expose Internal State

Look for ways to keep internal data inside the object. If a client calls a getter only to do something with the result, that logic often belongs on the object itself:

```php
// Bad: client has to know about items to count them
count($basket->getItems());

// Good: let the basket count itself
$basket->itemCount();
```

Absorb client-side `if`-on-getter patterns into the object:

```php
// Bad: domain knowledge scattered at call sites
if ($product->hasFixedPrice()) {
    $value = $product->fixedPrice();
} else {
    $value = $actualCost;
}

// Good: domain knowledge lives inside Product
$value = $product->determineValue($actualCost);
```

> **Naming convention:** Don't use the `get` prefix for query methods — use `itemCount()` not `getItemCount()`. This signals information retrieval, not instruction.

### 5.4 Objects Should Be Either Command or Query Objects

Apply CQS at the object level (CQRS): an object is either a **write model** (command object) or a **read model** (query object). Don't use your write model to ask questions from.

**CQRS with domain events:**

```php
// Write model: records events, doesn't expose data
namespace WriteModel {
    final class Player
    {
        public static function startAt(Position $position): Player { ... }
        public function moveLeft(int $steps): void { ... }
        public function moveRight(int $steps): void { ... }
        public function recordedEvents(): array { ... }
    }
}

// Read model: built from events, exposes data
namespace ReadModel {
    final class Player
    {
        public static function fromEvents(array $events): Player
        {
            $player = new self();
            foreach ($events as $event) {
                if ($event instanceof PlayerTookInitialPosition) {
                    $player->position = $event->position();
                }
                if ($event instanceof PlayerMovedLeft) {
                    $player->position = $player->position->toTheLeft($event->steps());
                }
                // ...
            }
            return $player;
        }

        public function currentPosition(): Position { ... }
    }
}
```

**CQRS with shared state:** write models expose a `state()` method (DTO) for persistence; read models use `fromState(array $state)` to rehydrate from the same database row.

> **Note on `fromState()`:** This is a legitimate exception to the "no property fillers" rule because it is part of a controlled serialization/deserialization boundary, not a general-purpose construction path.

### 5.5 Define Specific Methods and Return Types for the Queries You Want to Make

Every question deserves a dedicated method and a specific return type that represents the answer. Don't perform the full implementation inline — extract a named method and introduce an answer class.

### 5.6 Define an Abstraction for Queries That Cross System Boundaries

When answering a question requires crossing a system boundary (HTTP, filesystem, database), introduce an interface:

1. Use a **service interface** instead of a service class.
2. Leave implementation details out of the interface.

```php
// Abstraction
interface ExchangeRates
{
    public function exchangeRateFor(Currency $from, Currency $to): ExchangeRate;
}

// Concrete implementation
final class ExchangeRatesHttp implements ExchangeRates
{
    public function exchangeRateFor(Currency $from, Currency $to): ExchangeRate
    {
        $response = $this->httpClient->get(...);
        $rate = (float)json_decode($response->getBody())->data->rate;
        return ExchangeRate::from($from, $to, $rate);
    }
}

// Consumer only knows the interface
final class CurrencyConverter
{
    public function __construct(private ExchangeRates $exchangeRates) {}
}
```

> **Tip:** Not every question needs a new class. Extract a private method first. Only extract to a class if the method needs independent testing, becomes too large, or crosses a system boundary.

### 5.7 Use Stubs for Test Doubles with Query Methods

Replace query dependencies with **stubs** or **fakes** you write yourself. Do not use mocking tools for query methods — you should not verify the number of calls made.

```php
final class ExchangeRatesFake implements ExchangeRates
{
    private array $rates = [];

    public function setExchangeRate(Currency $from, Currency $to, float $rate): void
    {
        $this->rates[$from->asString()][$to->asString()] = ExchangeRate::from($from, $to, $rate);
    }

    public function exchangeRateFor(Currency $from, Currency $to): ExchangeRate
    {
        return $this->rates[$from->asString()][$to->asString()];
    }
}
```

### 5.8 Query Methods Should Use Other Query Methods, No Command Methods

A query chain should never contain a call to a command method — commands have side effects, which violates query purity.

**Exception:** web controllers must return an HTTP response even when they perform a command. Solve this by separating the command call from the query call explicitly:

```php
public function __invoke(Request $request): Response
{
    $userId = $this->userRepository->nextIdentifier();
    $this->registerUser->register($userId, $request->get('username')); // command
    $newUser = $this->userReadModelRepository->getById($userId);       // query
    return new Response(200, json_encode($newUser));
}
```

### 5.9 Summary

Query methods have a single return type and no side effects. Throw or return Null Objects instead of `null`/`false`. Expose as little internal state as possible — move client-side logic into the object. Apply CQRS: separate write models from read models. Define abstractions for cross-boundary queries. Use self-written fakes/stubs in tests, never verify call counts on query methods.

---

## 6. Performing Tasks

### 6.1 Use Command Methods with a Name in the Imperative Form

Command methods have a `void` return type and a name in the imperative mood:

```php
public function sendReminderEmail(EmailAddress $recipient): void { ... }
public function saveRecord(Record $record): void { ... }
public function changePassword(HashedPassword $password): void { ... }
```

### 6.2 Limit the Scope of a Command Method, Use Events to Perform Secondary Tasks

A command method should do one primary thing. Use events for secondary effects.

**Guiding questions:**
- Would the method name need "and" to describe what it does?
- Could part of the work be done in a background process?

```php
// Bad: one method does too much
public function changeUserPassword(UserId $userId, string $password): void
{
    // ... change password ...
    $this->mailer->sendPasswordChangedEmail($userId); // secondary concern!
}

// Good: dispatch an event; let a listener handle the secondary concern
public function changeUserPassword(UserId $userId, string $password): void
{
    // ... change password ...
    $this->eventDispatcher->dispatch(new UserPasswordChanged($userId));
}

final class SendEmail
{
    public function whenUserPasswordChanged(UserPasswordChanged $event): void
    {
        $this->mailer->sendPasswordChangedEmail($event->userId());
    }
}
```

**Benefits of event-based decoupling:**
- New effects can be added without modifying the original method.
- The original service has fewer dependencies.
- Effects can be handled asynchronously.

### 6.3 Make Services Immutable From the Outside as Well as the Inside

Command methods must not update internal service state that would affect subsequent calls. A guiding question: *"Could I re-instantiate the service for every method call and observe the same behavior?"*

```php
// Bad: service remembers who was emailed — behavior changes over time
private array $sentTo = [];

public function sendConfirmationEmail(EmailAddress $recipient): void
{
    if (in_array($recipient, $this->sentTo)) return;
    // send email
    $this->sentTo[] = $recipient;
}
```

### 6.4 When Something Goes Wrong, Throw an Exception

Never return a special value to signal failure in a command method. Throw an `InvalidArgumentException` / `LogicException` for bad input, a `RuntimeException` for runtime failures.

### 6.5 Use Queries to Collect Information, Commands to Take the Next Steps

Command methods may call query methods to gather information. The reverse is not allowed. Avoid the anti-pattern of calling a query then a command on the same object at the call site — that knowledge belongs inside the called object:

```php
// Bad: caller encodes decision logic that belongs in Player
if ($obstacle->isOnTheRight()) {
    $player->moveLeft();
} elseif ($obstacle->isOnTheLeft()) {
    $player->moveRight();
}

// Good: Player knows how to handle the obstacle
$player->evade($obstacle);
```

### 6.6 Define an Abstraction for Commands That Cross System Boundaries

If a command method reaches outside the application (remote service, queue, filesystem), introduce an interface:

```php
interface Queue
{
    public function publishUserPasswordChangedEvent(UserPasswordChanged $event): void;
}

final class RabbitMQQueue implements Queue
{
    public function publishUserPasswordChangedEvent(UserPasswordChanged $event): void
    {
        $this->rabbitMqConnection->publish('user_events', 'user_password_changed', ...);
    }
}
```

> **Tip:** Start specific. Once you see three similar cases, generalise the interface.

### 6.7 Only Verify Calls to Command Methods with a Mock

- **Query methods:** use fakes/stubs; do not verify call counts.
- **Command methods:** use a mock or spy to verify that the command was called with the right arguments.

```php
// Using a spy (preferred: explicit assertions)
final class EventDispatcherSpy implements EventDispatcher
{
    private array $events = [];

    public function dispatch(object $event): void
    {
        $this->events[] = $event;
    }

    public function dispatchedEvents(): array
    {
        return $this->events;
    }
}

$eventDispatcher = new EventDispatcherSpy();
$service = new ChangePasswordService($eventDispatcher, ...);
$service->changeUserPassword($userId, ...);

assertEquals([new UserPasswordChanged($userId)], $eventDispatcher->dispatchedEvents());
```

### 6.8 Summary

Command methods have imperative names and `void` return types. Separate primary tasks from secondary effects using events. Services must be immutable on the inside too — command methods must not accumulate state. Define abstractions for cross-boundary commands. Use mocks or spies (not stubs) to verify command calls in tests.
