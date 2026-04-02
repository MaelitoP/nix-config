# Example Review Comments

Use these examples as a tone and quality reference.

## Good example — DDD boundary

- **File:** `src/Mention/Listening/Domain/Aggregate/Search/Command/UpdateSearchHandler.php:41`
- **Title:** Command handler mutates more than one aggregate root
- **Why it matters:** This handler loads `Search` and `MatchedArticle` and coordinates changes across both. That breaks our aggregate rules and assumes a transactional boundary we do not guarantee, especially with sharding.
- **Recommendation:** Keep this handler focused on one aggregate root. Persist the `Search` change and publish an event, then let the consuming aggregate react in its own event handler.
- **Confidence:** high

## Good example — Naming

- **File:** `src/Mention/Listening/Domain/Aggregate/Search/SearchUpdater.php:12`
- **Title:** Aggregate name sounds like a process, not a domain concept
- **Why it matters:** `SearchUpdater` suggests a service or workflow object, but this class owns state and business behavior. That makes the abstraction misleading and will encourage future logic to accrete around a process name instead of a domain concept.
- **Recommendation:** Rename toward the thing the object actually is. Depending on its responsibility, candidates could be `Search`, `SearchRevision`, or `SearchActivation`. If it is not a true aggregate root, demote it to a command/service object instead of keeping an aggregate-shaped class with a process name.
- **Confidence:** high

## Good example — Tests

- **File:** `tests/Mention/Listening/Domain/Aggregate/Search/Command/DisableSearchHandlerTest.php:1`
- **Title:** Missing failure-path coverage for already-disabled search
- **Why it matters:** The PR adds a guard around disabling an already-disabled search, but the tests only cover the happy path. That leaves the new branch unproven and makes regressions likely.
- **Recommendation:** Add a behavioral test covering the already-disabled case and assert the expected domain outcome, whether that is a no-op or a domain exception.
- **Confidence:** high

## Good example — Preference clearly labeled

- **File:** `src/Mention/Core/Foo/Bar.php:78`
- **Title:** Boolean argument hides two behaviors
- **Why it matters:** This is not a correctness issue, but `reindex($entity, true)` vs `reindex($entity, false)` makes call sites hard to read and easy to misuse.
- **Recommendation:** Split this into two explicit methods, for example `reindexInteractive()` and `reindexBatch()`.
- **Confidence:** medium

## Bad example

> This naming is not great and tests could maybe be better.

Why this is bad:
- no file/line
- no explanation
- no impact
- no concrete fix
- no severity
- no confidence
