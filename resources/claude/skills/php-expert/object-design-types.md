# Style Guide for Object Design — Part 3: Behavior & Field Guide
*Matthias Noback — © 2018*

Covers: Ch 7 (Changing Service Behavior), Ch 8–15 (Field Guide: controllers, app services, repos, entities, VOs, event listeners, read models, layers), Epilogue

---

## Part III: Changing the Behavior of Objects

---

## 7. Changing the Behavior of Services

### 7.1 Introduce Constructor Arguments to Make Behavior Configurable

Promote hard-coded values to constructor arguments:

```php
// Before: hard-coded path
public function log($message): void
{
    file_put_contents('/var/log/app.log', $message, FILE_APPEND);
}

// After: configurable path
final class FileLogger
{
    public function __construct(private string $filePath) {}

    public function log($message): void
    {
        file_put_contents($this->filePath, $message, FILE_APPEND);
    }
}
```

### 7.2 Introduce Constructor Arguments to Make Behavior Replaceable

When a significant piece of logic needs to be swapped, extract an abstraction (interface) and inject it:

```php
interface FileLoader
{
    /** @throws CouldNotLoadFile */
    public function loadFile(string $filePath): array;
}

final class JsonFileLoader implements FileLoader { ... }
final class XmlFileLoader implements FileLoader { ... }

final class ParameterLoader
{
    public function __construct(private FileLoader $fileLoader) {}
}

$loader = new ParameterLoader(new JsonFileLoader());
$loader = new ParameterLoader(new XmlFileLoader());
```

**Compose abstractions for more complex behavior:**

```php
// Support multiple formats via composition
final class MultipleLoaders implements FileLoader
{
    public function __construct(private array $loadersByExtension) {}

    public function loadFile(string $filePath): array
    {
        $ext = pathinfo($filePath, PATHINFO_EXTENSION);
        if (!isset($this->loadersByExtension[$ext])) {
            throw new CouldNotLoadFile(sprintf('No loader for extension "%s"', $ext));
        }
        return $this->loadersByExtension[$ext]->loadFile($filePath);
    }
}

$loader = new ParameterLoader(new MultipleLoaders([
    'json' => new JsonFileLoader(),
    'xml'  => new XmlFileLoader(),
]));
```

**Decorate existing behavior:**

```php
// Add environment variable replacement without modifying any existing loader
final class ReplaceEnvironmentVariables implements FileLoader
{
    public function __construct(
        private FileLoader $fileLoader,
        private array $envVariables
    ) {}

    public function loadFile(string $filePath): array
    {
        $parameters = $this->fileLoader->loadFile($filePath);
        foreach ($parameters as $key => $value) {
            $parameters[$key] = $this->envVariables[$value] ?? $value;
        }
        return $parameters;
    }
}

// Add caching without modifying any existing loader
final class CachedFileLoader implements FileLoader
{
    private array $cache = [];

    public function __construct(private FileLoader $realLoader) {}

    public function loadFile(string $filePath): array
    {
        return $this->cache[$filePath]
            ??= $this->realLoader->loadFile($filePath);
    }
}
```

### 7.3 Use Notification Objects or Event Listeners for Additional Behavior

When new secondary effects are needed without modifying existing logic, add event listeners. For tightly scoped notification contracts, consider a custom notification interface instead of a generic event dispatcher:

```php
interface ImportNotifications
{
    public function whenHeaderImported(string $file, array $header): void;
    public function whenLineImported(string $file, int $index): void;
    public function whenFileImported(string $file): void;
}

final class Importer
{
    public function __construct(private ImportNotifications $notify) {}

    public function import(string $csvDirectory): void
    {
        foreach (...) {
            $this->notify->whenHeaderImported($file, $header);
            $this->notify->whenLineImported($file, $index);
            $this->notify->whenFileImported($file);
        }
    }
}
```

### 7.4 Don't Use Inheritance to Change an Object's Behavior

Inheritance exposes internals, couples subclass to parent implementation, and offers none of the composition benefits (decorating, composing, swapping). Even the Template Method pattern is strictly inferior to composition — everything you can do with a protected abstract method you can do better with an injected interface.

```php
// Don't do this
class XmlFileParameterLoader extends ParameterLoader
{
    protected function loadFile(string $filePath): array { ... }
}

// Do this instead
final class ParameterLoader
{
    public function __construct(private FileLoader $fileLoader) {}
}
```

> **When is inheritance acceptable?** Only for strict type hierarchies (`Paragraph extends ContentBlock`). For code reuse in value objects and entities where DI isn't available, use **traits** instead of inheritance.

### 7.5 Mark Classes as Final by Default

Mark every class `final` unless you explicitly intend to build a type hierarchy. This forces clients to use composition and keeps internals truly private.

### 7.6 Mark Methods and Properties Private by Default

With `final` classes, there is no reason for `protected` anything. All properties and non-public-interface methods should be `private`.

### 7.7 Summary

Change service behavior via constructor arguments (configuration) or injected abstractions (strategy, composition, decoration). Never use inheritance; prefer composition. Mark all classes `final` and all members `private` by default to enforce clean encapsulation.

---

## Part IV: A Field Guide to Objects

---

## 8. Controllers

Controllers are the **entry points** of the application's object graph. They contain infrastructure code (HTTP request/response, CLI input/output) and translate incoming data into calls to application services or read model repositories.

**An object is a controller if:**
- A front controller calls it (it is an entry point into the service graph).
- It contains infrastructure code revealing the delivery mechanism.
- It calls an application service or a read model repository.

```php
// Web controller (Symfony example)
final class MeetupController extends AbstractController
{
    public function scheduleMeetupAction(Request $request): Response
    {
        $form = $this->createForm(ScheduleMeetupType::class);
        $form->handleRequest($request);

        if ($form->isSubmitted() && $form->isValid()) {
            // call application service
            return new RedirectResponse('/meetup-details/' . $meetup->meetupId());
        }

        return $this->render('scheduleMeetup.html.twig', ['form' => $form->createView()]);
    }
}

// CLI controller
final class ScheduleMeetupCommand extends Command
{
    public function execute(InputInterface $input, OutputInterface $output)
    {
        $title = $input->getArgument('title');
        // call application service
        $output->writeln('Meetup scheduled');
    }
}
```

---

## 9. Application Services

An application service has a **single method** representing a single use case. It receives primitive-type arguments (or a command DTO), converts them to value objects, works with domain objects, and persists the result.

**An object is an application service if:**
- It performs a single task.
- It contains no infrastructure code.
- It describes one use case that corresponds to a stakeholder's feature request.

```php
final class ScheduleMeetupService
{
    public function __construct(private MeetupRepository $meetupRepository) {}

    public function schedule(string $title, string $date, UserId $currentUserId): MeetupId
    {
        $meetup = Meetup::schedule(
            $this->meetupRepository->nextIdentity(),
            Title::fromString($title),
            ScheduledDate::fromString($date),
            $currentUserId
        );
        $this->meetupRepository->save($meetup);
        return $meetup->meetupId();
    }
}
```

**Using a command DTO:**

```php
final class ScheduleMeetup
{
    public string $title;
    public string $date;
}

public function schedule(ScheduleMeetup $command, UserId $currentUserId): MeetupId
{
    $meetup = Meetup::schedule(
        $this->meetupRepository->nextIdentity(),
        Title::fromString($command->title),
        ScheduledDate::fromString($command->date),
        $currentUserId
    );
    // ...
}
```

---

## 10. Write Model Repositories

A write model repository abstracts the persistence of a domain object. It offers methods to retrieve and save entities, hiding the storage technology.

**An object is a write model repository if:**
- It offers methods to retrieve and save a specific type of entity.
- Its interface hides the underlying storage technology.

```php
// Interface in the Domain layer
namespace Domain\Model\Meetup;

interface MeetupRepository
{
    public function save(Meetup $meetup): void;
    public function nextIdentity(): MeetupId;

    /** @throws MeetupNotFound */
    public function getById(MeetupId $meetupId): Meetup;
}

// Implementation in the Infrastructure layer
namespace Infrastructure\Persistence\DoctrineOrm;

final class DoctrineOrmMeetupRepository implements MeetupRepository
{
    public function __construct(
        private EntityManager $entityManager,
        private UuidFactoryInterface $uuidFactory
    ) {}

    public function save(Meetup $meetup): void
    {
        $this->entityManager->persist($meetup);
        $this->entityManager->flush($meetup);
    }

    public function nextIdentity(): MeetupId
    {
        return MeetupId::fromString($this->uuidFactory->uuid4()->toString());
    }
}
```

---

## 11. Entities

Entities represent domain concepts with a unique identity and a lifecycle. They use named constructors, command methods, and produce domain events when state changes.

**An object is an entity if:**
- It has a unique identifier.
- It has a lifecycle (create → modify → possibly discard).
- It is persisted by a write model repository.
- It uses named constructors and command methods.
- It produces domain events when instantiated or modified.

---

## 12. Value Objects

Value objects wrap primitive values, adding domain meaning and invariant enforcement. They are immutable.

**An object is a value object if:**
- It is immutable.
- It wraps primitive-type data.
- It adds domain-specific meaning (e.g., `Year`, `EmailAddress`, not just `int`, `string`).
- It enforces constraints via constructor validation.
- It attracts related behavior (e.g., `Position::toTheLeft(int $steps)`).

```php
namespace Domain\Model\Meetup;

final class Meetup
{
    private array $events = [];
    private MeetupId $meetupId;
    private Title $title;
    private ScheduledDate $scheduledDate;
    private UserId $userId;

    private function __construct() {}

    public static function schedule(
        MeetupId $meetupId,
        Title $title,
        ScheduledDate $scheduledDate,
        UserId $userId
    ): Meetup {
        $meetup = new self();
        $meetup->meetupId      = $meetupId;
        $meetup->title         = $title;
        $meetup->scheduledDate = $scheduledDate;
        $meetup->userId        = $userId;
        $meetup->recordThat(new MeetupScheduled($meetupId, $title, $scheduledDate, $userId));
        return $meetup;
    }

    public function reschedule(ScheduledDate $scheduledDate): void
    {
        // ... state changes ...
        $this->recordThat(new MeetupRescheduled($this->meetupId, $scheduledDate));
    }

    private function recordThat(object $event): void { $this->events[] = $event; }
    public function releaseEvents(): array            { return $this->events; }
    public function clearEvents(): void               { $this->events = []; }
}

final class Title
{
    private function __construct(private string $title)
    {
        Assertion::notEmpty($title);
    }

    public static function fromString(string $title): self
    {
        return new self($title);
    }

    public function abbreviated(string $ellipsis = '...'): string { ... }
}
```

---

## 13. Event Listeners

Event listeners respond to domain events produced by the write model. They perform secondary effects (send emails, update read models, publish messages, etc.).

The application service fetches recorded events from the entity and hands them to an event dispatcher:

```php
final class RescheduleMeetupService
{
    public function reschedule(MeetupId $meetupId, ...): void
    {
        $meetup = ...;
        $meetup->reschedule(...);
        $this->dispatcher->dispatch($meetup->releaseEvents());
    }
}
```

An event listener handles the secondary action:

```php
// Naming convention: class = what you do, method = why/when you do it
final class NotifyGroupMembers
{
    public function whenMeetupRescheduled(MeetupRescheduled $event): void
    {
        // Send emails to group members
    }
}
```

---

## 14. Read Models and Read Model Repositories

Read models are **query objects**: immutable, designed for a specific use case, containing exactly the data needed and no more. They are DTOs that carry primitive-type values back to the world outside.

**An object is a read model if:**
- It has only query methods (is a query object / immutable).
- It is designed for a specific use case.
- All required data is available the moment you retrieve the object.

**An object is a read model repository if:**
- It has query methods conforming to a specific use case.
- It returns read models specific to that use case.

```php
namespace Application\UpcomingMeetups;

// Read model DTO
final class UpcomingMeetup
{
    public string $title;
    public string $date;
}

// Repository interface (Application layer)
interface UpcomingMeetupRepository
{
    /** @return UpcomingMeetup[] */
    public function upcomingMeetups(DateTimeImmutable $today): array;
}

// Repository implementation (Infrastructure layer)
final class UpcomingMeetupDoctrineDbalRepository implements UpcomingMeetupRepository
{
    public function __construct(private Connection $connection) {}

    public function upcomingMeetups(DateTimeImmutable $today): array
    {
        $rows = $this->connection->...;
        return array_map(function (array $row) {
            $model = new UpcomingMeetup();
            $model->title = $row['title'];
            $model->date  = $row['date'];
            return $model;
        }, $rows);
    }
}
```

---

## 15. Abstractions, Concretions, Layers, and Dependencies

### Object Types and Their Abstraction Level

| Object Type | Needs Interface? | Reasoning |
|---|---|---|
| Controllers | No | Infrastructure-specific; switch frameworks → rewrite |
| Application services | No | Represent a specific use case; change with the story |
| Entities & value objects | No | Specific domain knowledge; evolved, not substituted |
| Read model objects | No | Specific DTOs for a use case |
| Write model repositories | **Yes** | Reach outside the application; implementation varies |
| Read model repositories | **Yes** | Reach outside the application; implementation varies |
| Other cross-boundary services | **Yes** | Same reason as repositories |

### The Three Layers

```
┌──────────────────────────────────────────────┐
│              Infrastructure Layer             │
│  Controllers, Repository Implementations,    │
│  External Service Implementations            │
├──────────────────────────────────────────────┤
│              Application Layer               │
│  Application Services, Command DTOs,         │
│  Read Models, Read Model Repository          │
│  Interfaces, Event Listeners                 │
├──────────────────────────────────────────────┤
│               Domain Layer                   │
│  Entities, Value Objects,                    │
│  Write Model Repository Interfaces           │
└──────────────────────────────────────────────┘
```

Dependencies flow **downward only**: Infrastructure depends on Application which depends on Domain. Domain never depends on Application or Infrastructure.

**Benefits of this layering:**
1. The application and domain layers can be tested without a real database, HTTP server, etc. — all cross-boundary dependencies are interfaces with easy-to-write test doubles.
2. Infrastructure can be replaced (swap frameworks, swap databases, swap third-party services) without touching domain or application code.

---

## Epilogue

### Architectural Patterns

A layered architecture naturally leads to the **Hexagonal Architecture** (Ports & Adapters) pattern: identify all the ways your application communicates with the world outside, and build a clean port (interface) + adapter (implementation) pair for each one. This separates core application code from delivery-mechanism details.

### Testing

**Class testing vs. object testing:** Testing classes tends to produce white-box tests that are coupled to implementation. Prefer **black-box object tests** that exercise behaviour as perceived from the outside, using real collaborators except for cross-boundary dependencies.

**Top-down feature development:** Start from the biggest picture (acceptance criteria, high-level scenarios) and descend to implementation details. Write tests that define the expected end-to-end behaviour first, then make them pass by implementing layer by layer.

### Domain-Driven Design

For guidance on what objects your application should have and what their responsibilities should be, DDD is an excellent complement to the rules in this book. Key resources: *Domain-Driven Design* by Eric Evans, and *Implementing Domain-Driven Design* by Vaughn Vernon.

---

*© 2018 Matthias Noback. Published via Leanpub.*
