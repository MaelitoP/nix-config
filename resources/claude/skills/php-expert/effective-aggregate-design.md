# Effective Aggregate Design
*Vaughn Vernon — vvernon@shiftmethod.com — @VaughnVernon*

---

## Table of Contents

- [Part I: Modeling a Single Aggregate](#part-i-modeling-a-single-aggregate)
- [Part II: Making Aggregates Work Together](#part-ii-making-aggregates-work-together)
- [Part III: Gaining Insight Through Discovery](#part-iii-gaining-insight-through-discovery)
- [Rules Summary](#rules-summary)
- [References](#references)

---

## Part I: Modeling a Single Aggregate

Clustering **entities** and **value objects** into an **aggregate** with a carefully crafted consistency boundary may at first seem like quick work, but among all DDD tactical guidance, this pattern is one of the least well understood.

Common questions arise: Is an aggregate just a way to *cluster* a graph of closely related objects under a common parent? Is there a practical limit to the number of objects allowed in the graph? Since one aggregate instance can reference other aggregate instances, can associations be navigated deeply, modifying various objects along the way? And what is this concept of *invariants* and a *consistency boundary* all about? It is the answer to this last question that greatly influences the answers to the others.

There are various ways to model aggregates incorrectly. We could fall into the trap of designing for compositional convenience and make them too large. At the other end of the spectrum we could strip all aggregates bare, and as a result fail to protect true invariants. It is imperative to avoid both extremes and instead pay attention to the business rules.

---

### Designing a Scrum Management Application

The best way to explain aggregates is with an example. A fictitious company is developing a Scrum-based project management application called *ProjectOvation*. It follows the traditional Scrum model — product, product owner, team, backlog items, planned releases, and sprints. It is a subscription-based SaaS application. Each subscribing organization is registered as a *tenant*.

The Scrum terminology forms the starting point of the **ubiquitous language**. The team's experience with DDD is limited, meaning they will make mistakes as they climb the learning curve. Their struggles illustrate how to recognise and change unfavourable situations.

The team considered the following statements in the ubiquitous language:

- Products have backlog items, releases, and sprints.
- New product backlog items are planned.
- New product releases are scheduled.
- New product sprints are scheduled.
- A planned backlog item may be scheduled for release.
- A scheduled backlog item may be committed to a sprint.

---

### First Attempt: Large-Cluster Aggregate

The team put a lot of weight on the words "Products have" in the first statement — it sounded like composition, suggesting objects needed to be interconnected like an object graph. They added the following consistency rules:

- If a backlog item is committed to a sprint, we must not allow it to be removed from the system.
- If a sprint has committed backlog items, we must not allow it to be removed from the system.
- If a release has scheduled backlog items, we must not allow it to be removed from the system.
- If a backlog item is scheduled for release, we must not allow it to be removed from the system.

As a result, `Product` was modelled as a very large aggregate. The root object, `Product`, held all `BacklogItem`, all `Release`, and all `Sprint` instances associated with it:

```java
public class Product extends ConcurrencySafeEntity {
    private Set<BacklogItem> backlogItems;
    private String description;
    private String name;
    private ProductId productId;
    private Set<Release> releases;
    private Set<Sprint> sprints;
    private TenantId tenantId;
    ...
}
```

**Aggregate structure (Figure 1):**
```
        «aggregate root»
            Product
               |  1
    ┌──────────┼──────────┐
    ↓ 0..*     ↓ 0..*     ↓ 0..*
«entity»   «entity»   «entity»
BacklogItem  Release    Sprint
```

#### The Problem: Transactional Failures

The big aggregate looked attractive but was not truly practical. Once running in a multi-user environment it regularly experienced transactional failures. Aggregate instances employ **optimistic concurrency** to protect persistent objects from simultaneous overlapping modifications — objects carry a version number that is incremented on change and checked before saving.

Consider a common multi-client scenario:

1. Two users, Bill and Joe, view the same `Product` marked as **version 1** and begin to work on it.
2. Bill plans a new `BacklogItem` and commits. The `Product` version is incremented to **2**.
3. Joe schedules a new `Release` and tries to save, but his commit **fails** because it was based on `Product` version 1.

Nothing about planning a new backlog item should logically interfere with scheduling a new release. At the heart of the issue, the large-cluster aggregate was designed with **false invariants** in mind, not real business rules. These false invariants are artificial constraints imposed by developers. Besides causing transactional issues, the design also has performance and scalability drawbacks.

---

### Second Attempt: Multiple Aggregates

Consider an alternative model with **four distinct aggregates**. Each of the dependencies is associated by inference using a common `ProductId`:

```
«aggregate root»          «value object»
    Product       ──────►   ProductId
                               ▲  ▲  ▲
«aggregate root»  «aggregate root»  «aggregate root»
  BacklogItem         Release           Sprint
```

Breaking the large aggregate into four changes the method contracts on `Product`. With the large-cluster design, methods were CQS **commands** (void return, modify internal collections):

```java
public class Product ... {
    public void planBacklogItem(
        String aSummary, String aCategory,
        BacklogItemType aType, StoryPoints aStoryPoints) { ... }

    public void scheduleRelease(
        String aName, String aDescription,
        Date aBegins, Date anEnds) { ... }

    public void scheduleSprint(
        String aName, String aGoals,
        Date aBegins, Date anEnds) { ... }
}
```

With the multiple-aggregate design, the methods become CQS **queries** acting as **factories** — they create and return a new aggregate instance:

```java
public class Product ... {
    public BacklogItem planBacklogItem(
        String aSummary, String aCategory,
        BacklogItemType aType, StoryPoints aStoryPoints) { ... }

    public Release scheduleRelease(
        String aName, String aDescription,
        Date aBegins, Date anEnds) { ... }

    public Sprint scheduleSprint(
        String aName, String aGoals,
        Date aBegins, Date anEnds) { ... }
}
```

The transactional application service coordinates persistence:

```java
public class ProductBacklogItemService ... {
    @Transactional
    public void planProductBacklogItem(
        String aTenantId, String aProductId,
        String aSummary, String aCategory,
        String aBacklogItemType, String aStoryPoints) {

        Product product =
            productRepository.productOfId(
                new TenantId(aTenantId),
                new ProductId(aProductId));

        BacklogItem plannedBacklogItem =
            product.planBacklogItem(
                aSummary,
                aCategory,
                BacklogItemType.valueOf(aBacklogItemType),
                StoryPoints.valueOf(aStoryPoints));

        backlogItemRepository.add(plannedBacklogItem);
    }
}
```

Any number of `BacklogItem`, `Release`, and `Sprint` instances can now be safely created by simultaneous user requests. The transaction failure issue is modelled away.

---

### Rule: Model True Invariants In Consistency Boundaries

When trying to discover aggregates in a bounded context, we must understand the model's **true invariants**. Only with that knowledge can we determine which objects should be clustered into a given aggregate.

An **invariant** is a business rule that must always be consistent. When discussing invariants in aggregate design, we refer specifically to **transactional consistency** (as opposed to eventual consistency).

Example invariant:

```
c = a + b
```

When `a = 2` and `b = 3`, then `c` must be `5`. To ensure consistency, we model a boundary around these specific attributes:

```
AggregateType1 {
    int a; int b; int c;
    operations...
}
```

The consistency boundary logically asserts that everything inside adheres to a specific set of business invariant rules no matter what operations are performed. The consistency of everything outside this boundary is irrelevant to the aggregate.

> **Aggregate is synonymous with transactional consistency boundary.**

A properly designed aggregate can be modified in any way required by the business with its invariants completely consistent within a **single transaction**. A properly designed bounded context modifies **only one aggregate instance per transaction** in all cases.

Since aggregates must be designed with a consistency focus, the user interface should concentrate each request to execute a single command on just one aggregate instance.

> **Aggregates are chiefly about consistency boundaries, not about designing object graphs.**

---

### Rule: Design Small Aggregates

Even if every transaction were guaranteed to succeed, large aggregates still limit performance and scalability.

Consider adding a single backlog item to a `Product` that is years old and already has thousands of backlog items. Even with lazy loading (e.g., Hibernate), thousands of backlog items would be loaded into memory just to add one new element. Sometimes multiple large collections must be loaded simultaneously — for example, when scheduling a backlog item for release.

This large-cluster aggregate will never perform or scale well. It was deficient from the start because false invariants and a desire for compositional convenience drove the design.

**What does "small" mean?** Limit the aggregate to just the root entity and a minimal number of attributes and/or value-typed properties. The correct minimum is those that are *necessary*, and no more.

**Necessary** means: those attributes that must be consistent with each other, even if domain experts don't specify them as explicit rules. For example, `Product` has `name` and `description`. We can't imagine these being inconsistent — changing one almost always implies changing the other. Even though domain experts may not think of this as an explicit rule, it is an implicit one.

#### Prefer Value Objects Over Entities for Contained Parts

When considering whether a contained part should be an entity, first ask: must this part change over time, or can it be completely replaced when change is necessary? If instances can be completely replaced, that points to a **value object** rather than an entity.

Advantages of limiting internal parts to values:
- Values can be serialised with the root entity; entities typically require separately tracked storage.
- Overhead is higher with entity parts (e.g., SQL joins in Hibernate vs. reading a single table row).
- Value objects are smaller and safer to use (fewer bugs).
- Immutability makes unit tests easier to write and verify.

> **Practical data point:** On one financial derivatives project, approximately 70% of all aggregates were designed with just a root entity containing value-typed properties. The remaining 30% had just two to three total entities.

**Smaller aggregates:**
- Perform and scale better.
- Are biased toward transactional success (commit conflicts are rare).
- Make the system more usable.

When you encounter a true consistency rule, add another entity or collection as necessary — but continue to push yourself to keep the overall size as small as possible.

---

### Don't Trust Every Use Case

Use cases do not always carry the perspective of domain experts and the close-knit modelling team. A common issue is a use case that calls for the modification of multiple aggregate instances in a single transaction. In such a case, determine whether the specified large user goal spans multiple persistence transactions or if it occurs within just one. If it is the latter, be **sceptical**.

Trying to keep multiple aggregate instances consistent may indicate that your team has **missed an invariant**. You may end up folding multiple aggregates into one new concept with a new name to address the newly recognised business rule.

Conversely, a new use case may push you to remodel — but forming one large aggregate from multiple ones may recreate all the problems of large-cluster design. Often the business goal can be achieved with **eventual consistency** between aggregates instead. The team should critically examine use cases and challenge their assumptions, and may need to rewrite the use case to specify eventual consistency and an acceptable update delay.

---

## Part II: Making Aggregates Work Together

Part I focused on the design of small aggregates and their internals. Part II covers how aggregates reference other aggregates, and how to leverage eventual consistency to keep separate aggregate instances in harmony.

When designing aggregates, we may desire a compositional structure allowing for traversal through deep object graphs — but that is **not** the motivation of the pattern. DDD states that one aggregate may hold references to the root of other aggregates. However, this does **not** place the referenced aggregate inside the consistency boundary of the referencing one. There are still two (or more) separate aggregates.

In Java, a direct object reference looks like:

```java
public class BacklogItem extends ConcurrencySafeEntity {
    ...
    private Product product;
    ...
}
```

This has important implications:

1. Both the referencing aggregate (`BacklogItem`) and the referenced aggregate (`Product`) **must not be modified in the same transaction**. Only one may be modified per transaction.
2. If you are modifying multiple instances in a single transaction, it may be a strong indication that your **consistency boundaries are wrong** — a concept of your ubiquitous language has not yet been discovered.
3. If collapsing into a single aggregate would create a large-cluster aggregate, it may be an indication to use **eventual consistency** instead of atomic consistency.

---

### Rule: Reference Other Aggregates By Identity

Prefer references to external aggregates **only by their globally unique identity**, not by holding a direct object reference.

```java
// Before: direct object reference
public class BacklogItem extends ConcurrencySafeEntity {
    private Product product;
}

// After: reference by identity
public class BacklogItem extends ConcurrencySafeEntity {
    private ProductId productId;
}
```

**Benefits of reference by identity:**
- Aggregates are automatically smaller because references are never eagerly loaded.
- Instances require less time to load and take less memory.
- Less memory allocation overhead and reduced garbage collection pressure.
- Enables scalability and distribution (persistent state can be moved around).

#### Model Navigation

Reference by identity does not completely prevent model navigation. The recommended approach is to use a **repository or domain service** to look up dependent objects *before* invoking the aggregate behaviour. A client application service controls this:

```java
public class ProductBacklogItemService ... {
    @Transactional
    public void assignTeamMemberToTask(
        String aTenantId,
        String aBacklogItemId,
        String aTaskId,
        String aTeamMemberId) {

        BacklogItem backlogItem =
            backlogItemRepository.backlogItemOfId(
                new TenantId(aTenantId),
                new BacklogItemId(aBacklogItemId));

        Team ofTeam =
            teamRepository.teamOfId(
                backlogItem.tenantId(),
                backlogItem.teamId());

        backlogItem.assignTeamMemberToTask(
            new TeamMemberId(aTeamMemberId),
            ofTeam,
            new TaskId(aTaskId));
    }
}
```

Having an application service resolve dependencies frees the aggregate from relying on either a repository or a domain service. Referencing multiple aggregates in one request does **not** give licence to modify two or more of them.

> **Note on CQRS:** Limiting a model to reference by identity could make it more difficult to serve clients that assemble and render user interface views. If query overhead causes performance issues, consider CQRS.

#### Scalability and Distribution

Since aggregates reference by identity rather than direct pointer, their persistent state can be moved around to reach large scale. Almost-infinite scalability is achieved by allowing continuous repartitioning of aggregate data storage.

Distribution extends beyond storage. In event-driven architectures, message-based domain events containing aggregate identities are sent across bounded contexts. Message subscribers use the identities to carry out operations in their own domain models. Transactions across distributed systems are not atomic — the various systems bring multiple aggregates into a consistent state *eventually*.

---

### Rule: Use Eventual Consistency Outside the Boundary

From *Domain-Driven Design* (p. 128):

> Any rule that spans AGGREGATES will not be expected to be up-to-date at all times. Through event processing, batch processing, or other update mechanisms, other dependencies can be resolved within some specific time.

If executing a command on one aggregate instance requires additional business rules to execute on one or more other aggregates, **use eventual consistency**.

**Ask domain experts** if they could tolerate some time delay between the modification of one instance and the others. Domain experts are often more comfortable with delayed consistency than developers expect — they remember the days prior to computer automation, when delays were common and immediate consistency was never guaranteed.

#### Implementing Eventual Consistency with Domain Events

An aggregate command method publishes a domain event that is delivered to one or more asynchronous subscribers:

```java
public class BacklogItem extends ConcurrencySafeEntity {
    ...
    public void commitTo(Sprint aSprint) {
        ...
        DomainEventPublisher
            .instance()
            .publish(new BacklogItemCommitted(
                this.tenantId(),
                this.backlogItemId(),
                this.sprintId()));
    }
}
```

Each subscriber then retrieves a different aggregate instance and executes its behaviour based on the event. Each subscriber executes in a **separate transaction**, obeying the rule of modifying just one aggregate instance per transaction.

If the subscriber experiences concurrency contention, the modification can be retried — the message will be redelivered, a new transaction started, and the command re-executed. If complete failure occurs it may be necessary to compensate or report the failure for manual intervention.

#### Asking Whose Job It Is

A simple and sound guideline from Eric Evans:

> When examining the use case (or story), ask whether it's the **job of the user** executing the use case to make the data consistent. If it is, try to make it transactionally consistent (while adhering to the other aggregate rules). If it is **another user's job, or the job of the system**, allow it to be eventually consistent.

This not only provides a convenient tie-breaker between transactional and eventual consistency, but helps gain a deeper understanding of the domain by exposing real system invariants.

---

### Reasons To Break the Rules

An experienced DDD practitioner may at times decide to persist changes to multiple aggregate instances in a single transaction, but only with good reason.

#### Reason 1: User Interface Convenience

Sometimes user interfaces allow users to create batches of items at once. If creating a batch of aggregate instances all at once is semantically no different than creating them one at a time repeatedly, it represents a reason to break the rule with impunity:

```java
public class ProductBacklogItemService ... {
    @Transactional
    public void planBatchOfProductBacklogItems(
        String aTenantId, String productId,
        BacklogItemDescription[] aDescriptions) {

        Product product =
            productRepository.productOfId(
                new TenantId(aTenantId),
                new ProductId(productId));

        for (BacklogItemDescription desc : aDescriptions) {
            BacklogItem plannedBacklogItem =
                product.planBacklogItem(
                    desc.summary(),
                    desc.category(),
                    BacklogItemType.valueOf(desc.backlogItemType()),
                    StoryPoints.valueOf(desc.storyPoints()));
            backlogItemRepository.add(plannedBacklogItem);
        }
    }
}
```

> **Alternative:** Use a message bus to batch multiple application service invocations together as individual logical messages within a single physical message, processed in one transaction.

#### Reason 2: Lack of Technical Mechanisms

Eventual consistency requires out-of-band processing (messaging, timers, background threads). If the project has no such mechanism, modifying two or more aggregate instances in one transaction may be forced. Consider an additional factor: **user-aggregate affinity** — if business workflows are such that only one user focuses on one set of aggregate instances at any given time, the risk of invariant violations and transactional collisions is lower.

#### Reason 3: Global Transactions

Enterprise policies may require strict adherence to global, two-phase commit transactions. Even so, try to avoid modifying multiple aggregate instances within your local bounded context — at a minimum you can prevent transactional contention in your core domain.

#### Reason 4: Query Performance

There may be times when it is best to hold direct object references to other aggregates to ease repository query performance issues. These must be weighed carefully against potential size and overall performance trade-offs.

---

## Part III: Gaining Insight Through Discovery

Part III demonstrates how adhering to the aggregate rules affects a real Scrum model, and how the discovery process itself uncovers new domain insights.

### Rethinking the Design, Again

After breaking up the large-cluster `Product`, `BacklogItem` now stands alone as its own aggregate. The team composed a collection of `Task` instances inside the `BacklogItem` aggregate:

```
«aggregate root»          «value object»
  BacklogItem    ──────►    ProductId
  ────────────
  «value object»          «value object»
  BacklogItemId  ──────►   ReleaseId
  status
  story          ──────►  «value object»
  storyPoints               SprintId
  summary
  type
       ↓ 0..*
    «entity»           «value object»
      Task      0..* ► EstimationLogEntry
  ────────────         ──────────────────
  «value object»       description
  TaskId               hoursRemaining
  description          name
  hoursRemaining       volunteer
  name
  volunteer
```

A key invariant exists in the ubiquitous language:

- When progress is made on a backlog item task, the team member will estimate task hours remaining.
- When a team member estimates that **zero hours** remain on a specific task, the backlog item checks **all** tasks for any remaining hours. If no hours remain on any tasks, the backlog item status is automatically changed to **done**.
- When a team member estimates that **one or more hours** remain on a specific task and the backlog item's status is already **done**, the status is automatically **regressed**.

This seems like a true invariant: the backlog item's status is automatically and completely dependent on the total number of hours remaining across all its tasks.

---

### Estimating Aggregate Cost

Using back-of-the-envelope (BOTE) calculations for a typical sprint:

| Variable | Value | Reasoning |
|---|---|---|
| Sprint length | ~12 days | Between common 10-day and 15-day sprints |
| Hours per task | 12 hours | Tasks worked 1 hour/day over 12 days |
| Tasks per backlog item | 12 tasks | ~3 per layer (UI, application, domain, infrastructure) |
| Estimation logs per task | 12 entries | One per working day |
| **Total objects per backlog item** | **144** | 12 tasks × 12 logs |

With lazy loading (Hibernate), a re-estimation request loads at most: 1 backlog item + 12 tasks + 12 log entries for one task = **25 objects maximum**. That is a small aggregate. The higher end is only reached on the final day of the sprint.

---

### Common Usage Scenarios

Key observations from analysing common usage:

- During sprint planning, tasks are added one at a time — there is rarely a need for two team members to race to add tasks simultaneously.
- Daily estimations do not cause concurrency contention — only one team member adjusts a given task's hours.
- The backlog item's status is only affected at the very last estimation (the 144th, on the 12th task, on day 12). Any of the other 143 estimations leave the root entity's version unchanged.
- Using **story points** instead of task hours (experienced teams with known velocity) reduces estimation log entries per task to just one, almost eliminating memory overhead.

---

### Exploring Another Alternative: Task as a Separate Aggregate

The team considered splitting `Task` out as an independent aggregate (Figure 8). This would:

- Reduce composition overhead by 12 objects.
- Reduce lazy load overhead.
- Allow eager loading of estimation log entries.

However, this means the `BacklogItem` status can no longer be kept consistent *by transaction*. The team discussed this with domain experts and learned that a delay between the final zero-hour estimate and the status being set to done would be **acceptable**.

#### Implementing Eventual Consistency for Task/BacklogItem

When a `Task` processes an `estimateHoursRemaining()` command, it publishes a domain event:

```java
public class TaskHoursRemainingEstimated implements DomainEvent {
    private Date occurredOn;
    private TenantId tenantId;
    private BacklogItemId backlogItemId;
    private TaskId taskId;
    private int hoursRemaining;
    ...
}
```

A subscriber listens for this event and delegates to a domain service to:

1. Use `BacklogItemRepository` to retrieve the identified `BacklogItem`.
2. Use `TaskRepository` to retrieve all `Task` instances associated with the `BacklogItem`.
3. Execute `estimateTaskHoursRemaining()` on the `BacklogItem`, passing `hoursRemaining` and the retrieved tasks. The `BacklogItem` may transition its status.

An optimised approach uses a database aggregate query rather than loading all tasks:

```java
public class TaskRepositoryImpl implements TaskRepository {
    public int totalBacklogItemTaskHoursRemaining(
        TenantId aTenantId,
        BacklogItemId aBacklogItemId) {

        Query query = session.createQuery(
            "select sum(task.hoursRemaining) from Task task "
            + "where task.tenantId = ? and "
            + "task.backlogItemId = ?");
        ...
    }
}
```

#### UI Considerations for Eventual Consistency

Options for handling stale status in the user interface:
- Display a visual cue informing the user that the current status is uncertain, suggesting a time frame for checking back.
- The changed status will likely appear on the next rendered view.
- Background Ajax polling (inefficient — 143 of 144 re-estimations would not trigger a status update).
- Comet/Ajax Push (introduces new technology complexity).

---

### Is It the Team Member's Job?

Asking "whose job is it?" surfaces an important question: Does a team member care if the parent backlog item's status transitions to *done* the moment they set the last task's hours to zero? Or might a product owner or other stakeholder want to manually verify and mark completion?

- If **team members** should cause the automatic transition → tasks should likely be composed within the backlog item for transactional consistency.
- If a **product owner or external stakeholder** marks completion manually → neither transactional nor eventual consistency is necessary. Tasks could be split into a separate aggregate.

This reveals a **completely new domain concept**: teams should be able to configure a workflow preference for how backlog item completion is determined.

> Asking *whose job is it?* led to a few vital perceptions about the domain that would otherwise have been missed.

---

### Decision

The team decided to **keep `Task` within `BacklogItem`** for now, because:

- The current aggregate is fairly small (at most ~25 objects under typical load).
- Splitting introduces risk of leaving the true invariant unprotected.
- Users may experience a confusing stale status in the view with eventual consistency.
- The option to split remains available if performance tests reveal problems.

A quick win: extract the `story`/`useCaseDefinition` attribute into a lazily loaded value object or separate aggregate, reducing overhead without risking the invariant.

---

## Rules Summary

Four rules of thumb for effective aggregate design:

### 1. Model True Invariants In Consistency Boundaries
Identify the business rules that must *always* be transactionally consistent. Model only those tightly coupled attributes together in one aggregate. Everything else belongs outside.

### 2. Design Small Aggregates
Limit each aggregate to the root entity plus the minimum necessary attributes and value-typed properties. Favour value objects over entities for contained parts. Small aggregates perform better, scale better, and succeed in transactions more often.

### 3. Reference Other Aggregates By Identity
Hold only the globally unique identity of external aggregates, never a direct object reference. This keeps aggregates small, enables lazy loading by default, and supports distribution and scalability.

### 4. Use Eventual Consistency Outside the Boundary
When a command on one aggregate requires business rules to execute on another, publish a domain event and handle consistency asynchronously. Ask *whose job is it* to determine whether consistency should be transactional or eventual.

---

## References

| Reference | Details |
|---|---|
| [DDD] | Eric Evans; *Domain-Driven Design — Tackling Complexity in the Heart of Software*; 2003, Addison-Wesley, ISBN 0-321-12521-5 |
| [CQS] | Martin Fowler explains Bertrand Meyer's Command-Query Separation: http://martinfowler.com/bliki/CommandQuerySeparation.html |
| [CQRS — Dahan] | Udi Dahan; *Clarified CQRS*: http://www.udidahan.com/2009/12/09/clarified-cqrs/ |
| [CQRS — Fowler] | Martin Fowler; *CQRS*: http://martinfowler.com/bliki/CQRS.html |
| [CQRS — Young] | Greg Young; *CQRS and Event Sourcing*: http://codebetter.com/gregyoung/2010/02/13/cqrs-and-event-sourcing/ |
| [Helland] | Pat Helland; *Life beyond Distributed Transactions: an Apostate's Opinion*: http://www.ics.uci.edu/~cs223/papers/cidr07p15.pdf |
| [Hedhman] | Niclas Hedhman; http://www.jroller.com/niclas/ |
| [Qi4j] | Rickard Öberg, Niclas Hedhman; Qi4j framework: http://qi4j.org/ |
| [Cockburn] | Alistair Cockburn; *Hexagonal Architecture*: http://alistair.cockburn.us/Hexagonal+architecture |
| [Message Bus] | NServiceBus: http://www.nservicebus.com/ |
| [Pearls] | Jon Bentley; *Programming Pearls, Second Edition*: http://cs.bell-labs.com/cm/cs/pearls/bote.html |
| [Story Points] | Jeff Sutherland; *Story Points: Why are they better than hours?*: http://scrum.jeffsutherland.com/2010/04/story-points-why-are-they-better-than.html |
| [GoF] | Gamma, Helm, Johnson, Vlissides; *Design Patterns* — see Observer pattern |
| [POSA1] | Buschmann et al.; *Pattern-Oriented Software Architecture Vol. 1* — see Publisher-Subscriber pattern |

---

*Copyright © 2011 Vaughn Vernon. All rights reserved.*
*Licensed under the Creative Commons Attribution-NoDerivs 3.0 Unported License: http://creativecommons.org/licenses/by-nd/3.0/*
