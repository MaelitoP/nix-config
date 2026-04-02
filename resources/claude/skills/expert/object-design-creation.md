# Style Guide for Object Design — Part 1: Creating Objects
*Matthias Noback — @matthiasnoback — info@matthiasnoback.nl*
*© 2018 Matthias Noback*

Covers: Introduction, Ch 1 (Creating Services), Ch 2 (Creating Other Objects)

---

## Introduction

Between learning how to program and learning about advanced design patterns and principles, there isn't much educational material for object-oriented programmers. The books that are often recommended are hard to read, and it proves difficult to apply the theory to everyday coding problems.

This book closes part of that gap. The suggestions ("rules") are mostly short and simple. Following them helps move focus from trivial aspects of the code to the more interesting areas that deserve more attention. If everyone on a team follows the same suggestions, the code will have a more uniform style.

> **Goal:** This book can serve as part of an on-boarding process for new team members — hand it out alongside coding standards and style guides to establish good object design across the project.

### Two Types of Objects

In an application there are typically two types of objects:

1. **Service objects** — either perform a task, or return a piece of information. Created once, used any number of times, never changed after construction.
2. **Other objects** — hold data, and optionally expose behavior for manipulating that data. Can be created, used, and manipulated.

---

## Part I: The Lifecycle of an Object

---

## 1. Creating Services

Objects that perform a task are often called **services** (router, controller, logger, renderer, etc.). This chapter covers all relevant aspects of instantiating a service.

### 1.1 Inject Dependencies and Configuration Values as Constructor Arguments

Services need other services (dependencies) and configuration values to do their job. Both should be injected as constructor arguments so the service is ready for use immediately after instantiation:

```php
interface Logger
{
    public function log(string $message): void;
}

final class FileLogger implements Logger
{
    private Formatter $formatter;
    private string $logFilePath;

    public function __construct(Formatter $formatter, string $logFilePath)
    {
        $this->formatter = $formatter;
        $this->logFilePath = $logFilePath;
    }

    public function log(string $message): void
    {
        $formattedMessage = $this->formatter->format($message);
        file_put_contents($this->logFilePath, $formattedMessage, FILE_APPEND);
    }
}

$logger = new FileLogger(new DefaultFormatter(), '/var/log/app.log');
```

### 1.2 All Constructor Arguments Should Be Required

Optional constructor arguments (via `= null` or default values) unnecessarily complicate the code inside the class. Every dependency should be required.

```php
// Bad: optional dependency complicates internal code
final class BankStatementImporter
{
    private ?Logger $logger;

    public function __construct(Logger $logger = null)
    {
        $this->logger = $logger;
    }

    public function import(string $filePath): void
    {
        if ($this->logger instanceof Logger) { // guard needed everywhere
            $this->logger->log('A message');
        }
    }
}

// Good: always require the dependency; use a Null Object if needed
final class NullLogger implements Logger
{
    public function log(string $message): void
    {
        // Do nothing
    }
}

$importer = new BankStatementImporter(new NullLogger());
```

Similarly for configuration values — always require them explicitly. If a sensible default exists, expose it via a named factory method, not a default parameter:

```php
$metadataFactory = new MetadataFactory(Configuration::createDefault());
```

### 1.3 Only Use Constructor Injection

Setter injection violates two rules: it allows the object to be created in an incomplete state, and it breaks immutability after construction. Only use constructor injection.

```php
// Bad: setter injection
$importer = new BankStatementImporter();
$importer->setLogger($logger); // object was incomplete before this call

// Good: constructor injection only
$importer = new BankStatementImporter($logger);
```

### 1.4 There's No Such Thing as an Optional Dependency

You either need a dependency or you don't. Use a **Null Object** when a dependency is genuinely optional in behaviour terms.

### 1.5 Inject What You Need, Not Where You Can Get It From

Never inject a service locator just to retrieve actual dependencies from it. Declare the real dependencies explicitly as constructor arguments.

```php
// Bad: service locator hides real dependencies
final class HomepageController
{
    public function __construct(ServiceLocator $locator) { ... }

    public function __invoke(Request $request): Response
    {
        $user = $this->locator->get(EntityManager::class)->getRepository(User::class)->...;
        // ...
    }
}

// Good: inject what you actually need
final class HomepageController
{
    public function __construct(
        UserRepository $userRepository,
        ResponseFactory $responseFactory,
        TemplateRenderer $templateRenderer
    ) { ... }
}
```

> **Rule:** Always refine further. If you only need the `EntityManager` to fetch a repository, inject the repository directly instead.

### 1.6 Make All Dependencies Explicit

Hidden dependencies — via static accessors, globally available functions, or system calls — should become explicit constructor arguments.

**Turn static dependencies into object dependencies:**

```php
// Bad
final class DashboardController
{
    public function __invoke(): Response
    {
        if (Cache::has('recent_posts')) { // hidden static dependency
            $recentPosts = Cache::get('recent_posts');
        }
    }
}

// Good
final class DashboardController
{
    private CacheProvider $cache;

    public function __construct(CacheProvider $cache)
    {
        $this->cache = $cache;
    }
}
```

**Turn complicated functions into object dependencies:**

```php
// Before: json_encode() is a hidden dependency
final class ConfigWriter
{
    public function write(array $config, string $targetFilePath): void
    {
        file_put_contents($targetFilePath, json_encode($config));
    }
}

// After: wrap the function in an injectable service
final class JsonEncoder
{
    public function encode(array $data): string
    {
        return json_encode($data, JSON_THROW_ON_ERROR | JSON_FORCE_OBJECT);
    }
}

final class ConfigWriter
{
    private JsonEncoder $jsonEncoder;

    public function __construct(JsonEncoder $jsonEncoder)
    {
        $this->jsonEncoder = $jsonEncoder;
    }

    public function write(array $config, string $targetFilePath): void
    {
        file_put_contents($targetFilePath, $this->jsonEncoder->encode($config));
    }
}
```

> **Note:** Pure functions (`array_keys()`, `strpos()`, etc.) do not need wrapping. Only wrap functions that hide significant complexity or side effects.

**Make system calls explicit:**

```php
// System clock is a hidden dependency
interface Clock
{
    public function currentTime(): DateTimeImmutable;
}

final class SystemClock implements Clock
{
    public function currentTime(): DateTimeImmutable
    {
        return new DateTimeImmutable();
    }
}

final class FixedClock implements Clock
{
    public function __construct(private DateTimeImmutable $now) {}

    public function currentTime(): DateTimeImmutable
    {
        return $this->now;
    }
}

// Now testable with deterministic time
$repo = new MeetupRepository(new FixedClock(new DateTimeImmutable('2018-12-24 11:16:05')));
```

### 1.7 Data Relevant for the Task Should Be Passed as Method Arguments

Task-specific and contextual data (the entity being processed, the current user, the current request) should be method arguments, not constructor arguments. A guiding question: *"Could I run this service in a batch without re-instantiating it?"*

> **Signal word:** "current" — "the current time", "the currently logged-in user ID", "the current web request" — are all signs that data is contextual and should be a method argument.

```php
// Bad: entity as constructor argument forces re-instantiation per job
$entityManager = new EntityManager($user);
$entityManager->save();

// Good: entity as method argument
final class EntityManager
{
    public function save(object $entity): void { ... }
}
```

### 1.8 Don't Allow the Behavior of a Service to Change After Instantiation

Setters, `addListener()`/`removeListener()` methods, or flags that flip behavior make a service unpredictable. All dependencies and configuration values should be present from the start and must not change afterwards.

```php
// Bad: behavior changes after construction
$importer->ignoreErrors(false);

// Good: pass configuration as constructor argument
$importer = new Importer(ignoreErrors: false);
```

### 1.9 Do Nothing Inside a Constructor, Only Assign Properties

Constructors must only validate arguments and assign them to properties. No I/O, no computation, no side effects.

```php
// Bad: constructor creates filesystem resources
public function __construct(string $logFilePath)
{
    mkdir(dirname($logFilePath), 0777, true); // side effect!
    touch($logFilePath);
    $this->logFilePath = $logFilePath;
}

// Good: validate and assign only; push I/O to before construction
public function __construct(string $logFilePath)
{
    if (!is_writable($logFilePath)) {
        throw new InvalidArgumentException(
            sprintf('Log file path "%s" should be writable', $logFilePath)
        );
    }
    $this->logFilePath = $logFilePath;
}
```

> **Rule of thumb:** If changing the order of property assignments causes an error, you are doing too much in the constructor.

### 1.10 Throw an Exception When an Argument Is Invalid

Use assertions or manual checks in the constructor. Only assign after validation.

```php
final class Alerting
{
    public function __construct(int $minimumLevel)
    {
        if ($minimumLevel <= 0) {
            throw new InvalidArgumentException(
                'Minimum alerting level should be greater than 0'
            );
        }
        $this->minimumLevel = $minimumLevel;
    }
}
```

> **Tip:** Use an assertion library (`beberlei/assert`, `webmozart/assert`) to avoid writing the same guard patterns repeatedly.

> **Note:** Don't collect assertion exceptions into a list. Assertions are for programmers, not end-users. Fail immediately on the first violation.

### 1.11 Define Services as an Immutable Object Graph with Only a Few Entry Points

All services form one large immutable object graph. **Controllers are the entry points.** A service container should expose only controller methods publicly; all other service construction logic stays private.

```php
final class ServiceContainer
{
    public function homepageController(): HomepageController
    {
        return new HomepageController(
            $this->userRepository(),
            $this->responseFactory(),
            $this->templateRenderer()
        );
    }

    private function userRepository(): UserRepository { ... }
    private function responseFactory(): ResponseFactory { ... }
    private function templateRenderer(): TemplateRenderer { ... }
}
```

### 1.12 Summary

- Inject all dependencies and configuration as constructor arguments — all required, never optional.
- Only use constructor injection; no setters.
- Make all dependencies explicit; no service locators, no hidden static calls or system calls.
- Pass task-specific and contextual data as method arguments, not constructor arguments.
- Only assign properties in constructors; validate first and throw on invalid input.
- After construction, a service is immutable; all services form one large, reusable object graph.

---

## 2. Creating Other Objects

Besides services, there are **value objects** and **entities** — objects that hold data and optionally expose behavior for manipulating that data.

### 2.1 Require the Minimum Amount of Data Needed to Behave Consistently

Protect domain invariants in the constructor. Never allow an object to exist in an inconsistent state.

```php
// Bad: object can be in invalid state between setX/setY calls
$position = new Position();
$position->setX(45);
// position.distanceTo() would fail here

// Good: both coordinates required at construction
final class Position
{
    public function __construct(private int $x, private int $y) {}

    public function distanceTo(Position $other): float
    {
        return sqrt(($other->x - $this->x) ** 2 + ($other->y - $this->y) ** 2);
    }
}
```

### 2.2 Require Data That Is Meaningful

Validate that constructor arguments are semantically valid for their domain concept, not just syntactically correct.

```php
final class Coordinates
{
    public function __construct(float $latitude, float $longitude)
    {
        if ($latitude > 90 || $latitude < -90) {
            throw new InvalidArgumentException('Latitude should be between -90 and 90');
        }
        $this->latitude = $latitude;

        if ($longitude > 180 || $longitude < -180) {
            throw new InvalidArgumentException('Longitude should be between -180 and 180');
        }
        $this->longitude = $longitude;
    }
}
```

When multi-argument validation seems necessary, look for ways to redesign the object to eliminate it:

```php
// Bad: cross-argument validation is a smell
new Deal($totalAmount, $firstPartyGets, $secondPartyGets);

// Good: remove the redundant argument; let the object derive it
final class Deal
{
    public function __construct(int $firstPartyGets, int $secondPartyGets)
    {
        // validate each independently
    }

    public function totalAmount(): int
    {
        return $this->firstPartyGets + $this->secondPartyGets;
    }
}
```

Similarly, use named constructors to provide distinct creation paths instead of conditional multi-argument logic:

```php
// Instead of: new Line(isDotted: true, distanceBetweenDots: 5)
Line::dotted(5);
Line::solid();
```

### 2.3 Extract New Objects to Prevent Domain Invariants From Being Verified in Multiple Places

When the same validation logic appears in multiple places, extract a **value object**:

```php
// Bad: email validation duplicated in constructor and changeEmailAddress()
final class User
{
    public function __construct(string $emailAddress) {
        if (!filter_var($emailAddress, FILTER_VALIDATE_EMAIL)) { ... }
    }
    public function changeEmailAddress(string $emailAddress): void {
        if (!filter_var($emailAddress, FILTER_VALIDATE_EMAIL)) { ... }
    }
}

// Good: extract EmailAddress value object; validation lives once
final class EmailAddress
{
    public function __construct(string $emailAddress)
    {
        if (!filter_var($emailAddress, FILTER_VALIDATE_EMAIL)) {
            throw new InvalidArgumentException('Invalid email address');
        }
        $this->emailAddress = $emailAddress;
    }
}

final class User
{
    public function __construct(private EmailAddress $emailAddress) {}
    public function changeEmailAddress(EmailAddress $emailAddress): void
    {
        $this->emailAddress = $emailAddress;
    }
}
```

> **Guiding question:** "Would any `string`, `int`, etc. be acceptable here?" If no, introduce a class for the concept.

### 2.4 Extract New Objects to Represent Composite Values

When values always belong together and always travel together, wrap them in a new type:

```php
// Amount and Currency always go together — wrap them
final class Money
{
    public function __construct(Amount $amount, Currency $currency) { ... }
}
```

### 2.5 Use Assertions to Validate Constructor Arguments

Use an assertion library for guard clauses. The guiding question for whether to write a unit test: *"Would it be theoretically possible for the language runtime to catch this case?"* If yes, skip the test. If the check requires inspecting a value range or item count, write the test.

### 2.6 Don't Inject Dependencies, Optionally Pass Them as Method Arguments

Value objects and entities do not get dependencies injected in their constructor. If they need a service, pass it as a method argument:

```php
final class Money
{
    public function convert(ExchangeRate $exchangeRate): Money
    {
        Assertion::equals($this->currency, $exchangeRate->fromCurrency());
        return new Money(
            $exchangeRate->rate()->applyTo($this->amount),
            $exchangeRate->targetCurrency()
        );
    }
}
```

### 2.7 Use Named Constructors

For non-service objects, prefer `public static` factory methods over a standard `__construct()`. The private regular constructor prevents clients from creating incomplete objects.

```php
// Create from primitive type values
final class Date
{
    private function __construct() {}

    public static function fromString(string $date): Date
    {
        $object = new self();
        $object->date = DateTimeImmutable::createFromFormat('d/m/Y', $date);
        return $object;
    }
}

// Introduce domain-specific language
$salesOrder = SalesOrder::place(...);

// Named constructors for exceptions
throw CouldNotFindProduct::forId($productId);

final class CouldNotFindProduct extends RuntimeException
{
    public static function forId(ProductId $productId): self
    {
        return new self(sprintf('Could not find a product with ID "%s"', $productId));
    }
}
```

> **Warning:** Don't add a symmetric `toString()`, `toInt()`, etc. unless there is a proven need. Don't add them just for symmetry.

> **Warning:** Avoid property-filler methods (`fromArray(array $data)`) that bypass object control. Constructors should be fully controlled by the object.

### 2.8 Don't Put Anything More Into an Object Than It Needs

Design objects test-first to discover what data is truly needed. Do not pre-populate objects with data "just in case". Add data only when a real behavior requires it.

### 2.9 Don't Test Constructors

Only test the constructor for **failure scenarios** (invalid arguments). Do not test that valid arguments are correctly assigned — that forces unnecessary getters and couples the test to the implementation.

```php
// Only test failure
expectException(InvalidArgumentException::class, 'Latitude', function() {
    new Coordinates(-90.1, 0.0);
});

// Don't test success by adding getters just for the test
```

### 2.10 Summary

- Require the minimum meaningful data at construction; validate everything; throw on invalid input.
- Wrap primitive values in value objects to centralise validation and add domain meaning.
- Use named constructors (static factory methods) to introduce domain-specific language.
- Never inject dependencies into non-service objects; pass them as method arguments if needed.
- Only add data, getters, and behavior when they are actually needed by a real behavior or client.
