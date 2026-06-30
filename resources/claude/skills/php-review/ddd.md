# DDD, Architecture, and Naming Review Rules

This file defines the domain and architecture rules for PR reviews.

## 1. Architecture intent

Our PHP monolith follows a hexagonal / onion / ports-and-adapters architecture:

- Business logic must not depend directly on infrastructure.
- Entities are business-oriented objects, not data bags.
- Persistence lives outside the domain model.
- Transaction boundaries must stay clear.
- Aggregates must stay small and consistent.

A review must flag code that weakens these properties.

## 2. Domain model shape

The domain model contains:

- entities
- value objects
- domain services
- commands
- events
- command handlers
- event handlers
- repository interfaces

The domain model must know nothing about persistence.

### Blocking examples

- entity calling persistence code
- domain object depending on infrastructure service just to save itself
- entity with persistence lifecycle logic
- domain code that relies on doctrine execution timing

## 3. Entities

### Hard rules

- Entities are plain PHP objects with identity.
- Entities expose business actions, not setters.
- Root entities may expose public business methods.
- Public business methods on roots should be imperative verbs.
- Non-root entities may have business methods, but they must be `@internal` and only used inside the same aggregate.
- Entities may have public getters.
- Entities must not have public setters.
- Entities must not call parent entities.
- Entities must use `VersionTrait`.
- Entities exposing IDs must return value objects.
- Entities referencing other aggregates must do so by ID value object, not object reference.
- Root entities must receive their ID in the constructor.
- Root entities should keep generated domain events in `pendingEvents`.
- Root entities should implement `Mention\DomainBase\Aggregate\AggregateRootInterface`.

### Review questions

- Is behavior on the right entity?
- Is any state mutation happening from outside instead of through a business action?
- Is this entity becoming data-oriented?
- Is a non-root entity leaking actions that should be guarded by the root?
- Is a root exposing too many low-level mutators?

## 4. Aggregates

### Hard rules

- An aggregate is a small object tree with exactly one root entity.
- All business actions must go through the root.
- Aggregates must stay small enough to reason about and persist safely.
- Large growing collections must not live inside another aggregate.

### Review questions

- Is this truly one aggregate, or several independent roots being manipulated together?
- Does the root enforce consistency?
- Is this collection unbounded and likely to become huge?
- Is this PR introducing a second root mutation in the same operation?

### Naming guidance

Aggregate names should represent stable domain concepts, not implementation details or workflows.

Good aggregate names usually:
- describe a business concept
- align with the ubiquitous language
- remain valid if the implementation changes

Weak aggregate names often:
- sound like processes (`Updater`, `Processor`, `Syncer`)
- sound like technical wrappers (`Manager`, `Service`, `Handler`)
- describe a use case rather than a domain concept
- hide that the object is not actually an aggregate

When reviewing naming:
- explain what the current name suggests
- explain what the code actually owns
- highlight the mismatch
- propose better alternatives

## 5. Value objects

### Hard rules

- Value objects represent values, not identities.
- Value objects are immutable.
- Value objects validate their invariants in the constructor.
- Objects with IDs are entities, not value objects.
- Do not hide value objects in generic `Value` or `ValueObject` namespaces unless the scope is truly generic.

### Review questions

- Is a scalar representing a restricted domain concept that should be a value object?
- Is a value object missing validation?
- Is a value object mutable?
- Is a value object misplaced in a generic namespace for no reason?

## 6. Domain services

Domain services are allowed when logic does not belong naturally to an entity or value object.

### Hard rules

- Domain services may access external services / APIs.
- Domain service methods must not have persistent effects, or must be idempotent.

### Review questions

- Is this really domain logic, or application / infrastructure logic?
- Is this "service" a dumping ground?
- Would a short-lived object or aggregate method be clearer?

## 7. Commands

### Hard rules

- Commands must live in a `\Command` namespace.
- Command names must end with `Command`.
- Commands must implement `Mention\DomainBase\MessageBus\MessageInterface`.
- Commands must not take entity objects as arguments.
- Commands must be instantiable from scalars, typically via `safeCreate`.
- Commands may have validation constraints.
- Commands must not enforce business invariants in the constructor.

### Review questions

- Is the command a plain message object?
- Is it accepting entities or rich domain objects it should not accept?
- Is input conversion pushed to the UI instead of handled safely?
- Is the name imperative and precise?

### Naming guidance

Good command names:
- are imperative
- describe one action
- name the business target clearly

Weak command names:
- are vague (`UpdateDataCommand`)
- describe implementation (`PersistFooCommand`)
- bundle multiple actions

## 8. Command handlers

### Hard rules

- Command handler must live in the same namespace as its command.
- Command handler must implement `CommandHandlerInterface`.
- Command handler must not validate or persist directly.
- Command handler may fetch exactly one aggregate root, or instantiate exactly one aggregate root.
- Command handler must call at most one method on the aggregate root.
- Command handler must not return anything.
- Command handler must not access other aggregates.
- Command handler must not access more than one aggregate root.

### Blocking examples

- handler loads two aggregates and coordinates both
- handler performs business logic itself instead of delegating
- handler mutates multiple roots
- handler persists / flushes directly

### Review questions

- Is the handler just orchestration around one aggregate action?
- Has business logic leaked out of the aggregate?
- Is the handler doing repository reads beyond the one root it owns?

## 9. Events

### Hard rules

- Events must be designed for serialization and long-term compatibility.
- Event names must be past tense.
- Event properties should be nullable from the consumer point of view.
- Properties must not change meaning.
- IDs in events must be global ID strings.
- Events should be defined in `.proto` files.
- All events must have `string clientTransactionId`.

### Review questions

- Does the event describe something that happened?
- Is the schema forward-compatible?
- Is the event carrying local persistence details that should not leak out?

## 10. Event handlers

### Hard rules

- Event handlers must implement `EventHandlerInterface`.
- Event handlers must live in the consuming aggregate.
- Event handlers must not act on aggregates outside their own namespace.
- Event handlers must not dispatch commands.
- Event handlers must be idempotent if they affect non-aggregates or more than one aggregate root.
- Event handlers must stay fast and avoid remote calls.

### Review questions

- Is this handler effectively a long-running worker hidden inside the event system?
- Does it touch remote APIs?
- Is idempotency required here and missing?

## 11. Repositories

### Hard rules

- The domain defines repository interfaces.
- Infrastructure implements repositories.
- Repositories are for fetching aggregate roots.

### Review questions

- Is this repository exposing persistence details into the domain?
- Is this code using repositories to bypass aggregate rules?
- Is this method really a fetch concern, or misplaced domain logic?

## 12. External data and actions

### Hard rules

- If a domain action needs external data, the data should be passed in.
- The domain model should not fetch external data itself.
- Multi-aggregate mutations must use events.
- One aggregate is strongly consistent; multiple aggregates are only eventually consistent.

### Review questions

- Is this aggregate action reaching out for external state instead of receiving it?
- Is this PR hiding cross-aggregate mutation inside one handler?

## 13. GraphQL and UI boundaries

### Hard rules

- The domain model must not know about GraphQL.
- UI concerns must stay outside the domain.

## 14. Naming checklist for reviewers

When a name is weak, do not just say "naming could be improved".
Explain the mismatch and propose alternatives.

Check whether the name:
- reflects the domain rather than the implementation
- matches the actual ownership of behavior
- is consistent with nearby concepts
- distinguishes aggregate vs command vs service vs handler vs policy vs DTO
- avoids overloaded terms like `Manager`, `Service`, `Handler`, `Utils`

Ask these questions:
- Is this a domain concept or a workflow?
- Is this really an aggregate root?
- Does this name still make sense if we swap implementation details?
- Does the name communicate scope and responsibility?
