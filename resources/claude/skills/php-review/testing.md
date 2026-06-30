# Testing Review Rules

This file defines review expectations for tests.

## 1. General expectations

Tests should cover behavior, not just implementation details.

A review should ask:
- what behavior changed?
- what branch or invariant changed?
- what breaks if this is wrong?
- do tests prove the new behavior?

## 2. Testing tools by layer

### Domain model

- The domain model should be tested.
- Prefer Behat / Cucumber-style tests for domain behavior and business scenarios.

### Single classes

- Use PHPUnit for unit tests.

### API

- REST API: use PHPUnit with `ApiTest`.
- GraphQL: use PHPUnit with `GraphQLTest`.

## 3. Success and failure paths

### Hard expectation

Tests should cover:
- success paths
- failure paths
- important edge cases
- all meaningful branches introduced by the PR

### Review questions

- Did the PR add a new guard without a failure-path test?
- Did the PR fix a bug without a regression test?
- Did the PR add branching behavior without tests for each branch?

## 4. No network services in tests

### Hard rules

- Tests should not depend on network services.
- Stub the code that calls the service.
- Prefer stubbing interfaces, not concrete classes.

### Review questions

- Is this test flaky because it talks to a real network service?
- Is the stub coupled to implementation through inheritance?
- Is the code under test accepting a concrete class where it should accept an interface?

## 5. Fixtures

### Hard rules

- Never modify shared fixtures casually.
- Reusing and mutating a fixture can silently invalidate existing tests.
- JSON fixtures should be normalized consistently when possible.

### Review questions

- Did the PR modify a fixture instead of creating a new one?
- Could this fixture change invalidate unrelated tests?

## 6. Doctrine listeners

When reviewing tests for doctrine listeners:
- assert the entity mutation
- refresh and assert persisted state when persistence behavior matters

## 7. What makes missing tests blocking?

Usually blocking:
- bug fix with no regression test
- behavior change in a critical path with no meaningful coverage
- risky branching logic with only happy-path coverage
- aggregate/business invariant changes with no behavioral test

Usually suggestion:
- simple refactor with preserved behavior but no direct tests added
- weak assertions where broad coverage already exists
- missing edge case on low-risk code

Usually nit:
- small assertion quality improvements
- naming/structure improvements in existing tests

## 8. Test quality checklist

Strong tests:
- prove the business outcome
- assert meaningful state or emitted events
- isolate external dependencies
- are readable enough to explain the scenario
- avoid coupling to irrelevant implementation details

Weak tests:
- only assert one trivial interaction
- duplicate production logic
- test mocks more than behavior
- depend on unstable external state

## 9. Review wording guidance

Do not say only:
- "missing tests"

Prefer:
- what behavior is unproven
- why that matters
- what kind of test would close the gap
