# Comment examples: before → after

Each pair shows a comment that fails the rule and the fix. The failure is named. Use these to calibrate; the languages are interchangeable — the rule is the same everywhere.

## 1. Mechanism / architecture → behavior + maintenance rule (Go)

The comment narrates the algorithm and justifies the design ("emergent", "no dedicated recovery code"), and drops implementation jargon (`SHA256`, the literal `in_progress`).

```go
// BEFORE
// CandidateIndices returns the indices to migrate, newest-first. It intersects
// the window's candidate names with the indices that exist on the source
// cluster, then drops the complete ones. An index left in_progress or failed by
// a prior crash is returned again. Re-scrolling is idempotent: DocIDs are
// SHA256(normalizedURL) and OpenSearch index ops overwrite, so crash recovery
// is emergent — there is no dedicated recovery code.
```

```go
// AFTER
// CandidateIndices returns the indices to migrate, newest first.
//
// It keeps only the indices that exist on the source cluster and skips the ones
// already marked complete.
//
// Indices left in progress or failed after a previous crash are returned again.
// Re-processing them is safe, so restarting the migration is enough to continue.
```

Why the after works: a maintainer learns the observable behavior (newest first, what's skipped) and the one rule that matters (re-running is safe). It doesn't explain *how* idempotency is achieved — that lives in the code that does the writing.

## 2. Selling the design / reviewer-facing prose → delete (any language)

The comment argues for the abstraction. The code already shows the interface; the rationale convinces a reviewer once and then rots.

```go
// BEFORE
// statusReader is a small consumer-side interface so the scheduler stays
// decoupled from the store and is unit-testable with in-package fakes without
// needing a real Redis.
type statusReader interface { ... }

// AFTER
// statusReader reports the migration status of a set of indices.
type statusReader interface { ... }
```

Why: "decoupled / unit-testable / without Redis" is design justification aimed at a reviewer, not a fact a maintainer needs while changing the code. Cut to one line of behavior — or nothing.

## 3. Narration that restates the code → delete (Python)

```python
# BEFORE
# loop over the users and send each one an email
for user in users:
    send_email(user)

# AFTER
for user in users:
    send_email(user)
```

Why: the code says exactly this. A comment that restates it is pure noise.

## 4. Restating the name → delete; or state the real constraint (PHP)

```php
// BEFORE
// Get the user id
public function getUserId(): int { ... }
```

```php
// AFTER  (delete — the name says it)
public function getUserId(): int { ... }

// AFTER  (only if there is a real rule worth stating)
// Returns 0 for the system actor; callers that grant permissions must handle it.
public function getUserId(): int { ... }
```

## 5. Implementation name-dropping → state the consequence (Rust)

```rust
// BEFORE
// Uses a HashMap<String, ()> as a set and a second pass with retain() to
// deduplicate before the rayon parallel map.
let unique: HashSet<_> = items.into_iter().collect();

// AFTER
// Deduplicate first; downstream work is expensive and must not run twice per item.
let unique: HashSet<_> = items.into_iter().collect();
```

Why: the types and calls are visible in the code. The maintenance rule (don't let duplicates reach the expensive step) is not.

## 6. Abstract wording + literal tokens → plain developer words (TypeScript)

```ts
// BEFORE
// Intersect the requested scopes with the granted scopes; the resulting
// array is newest-first and excludes any scope whose state === "revoked".
```

```ts
// AFTER
// Keeps only scopes that are both requested and granted, newest first, and
// skips revoked ones.
```

Why: "intersect", `===`, and the hyphenated `newest-first` make the reader decode the comment. "Keeps only… skips…" reads like a maintainer wrote it.

## 7. Comments that correctly PASS (do not touch these)

These state a non-obvious behavior, a maintenance rule, or a bug-preventing why, in plain words. Leave them.

```go
// candidateNames lists the index names for the window, newest first.
//
// It starts at the day before start and walks back to end, inclusive.
// AddDate is used so month ends, year changes, and leap years are handled correctly.
```

```python
# Stripe sends the event twice within a few seconds; key on event.id so the
# second delivery is a no-op.
```

```rust
// Must hold `lock` for the whole swap — a reader between the two stores sees a torn value.
```

```php
// Orders here are pre-tax on purpose; the invoicing job applies VAT later.
```

The test for "passes": remove the comment and ask whether a competent developer could still change the code safely. If the answer is no, the comment earns its place — keep it, in this plain voice.
