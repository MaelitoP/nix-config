# Example Review Comments (Go)

Use these as a tone and quality reference. Terse, concrete, with an idiomatic fix.

## Good example — Concurrency (blocking)

- **File:** `internal/worker/pool.go:58`
- **Title:** Goroutine started with no stop condition leaks under cancellation
- **Why it matters:** `go p.run()` is launched per job but `run` loops on `for range p.tasks` with nothing closing `p.tasks`, and it ignores the passed `ctx`. When the parent context is cancelled, these goroutines never exit — under load this leaks goroutines until OOM.
- **Recommendation:** Select on `ctx.Done()` and return, and close `tasks` from the sole sender on shutdown:
  ```go
  for {
      select {
      case <-ctx.Done():
          return
      case t, ok := <-p.tasks:
          if !ok {
              return
          }
          p.handle(t)
      }
  }
  ```
- **Confidence:** high

## Good example — Error handling (blocking)

- **File:** `internal/store/user.go:33`
- **Title:** Error from `row.Scan` is discarded, returning a zero-value User
- **Why it matters:** `_ = row.Scan(&u)` swallows the failure; callers get a zero `User` and `err == nil`, so a missing row reads as a valid empty user.
- **Recommendation:** Return the error, wrapping with context and a sentinel for the not-found case so callers can `errors.Is`:
  ```go
  if err := row.Scan(&u); err != nil {
      if errors.Is(err, sql.ErrNoRows) {
          return User{}, ErrUserNotFound
      }
      return User{}, fmt.Errorf("scan user %d: %w", id, err)
  }
  ```
- **Confidence:** high

## Good example — Idiom & naming (suggestion)

- **File:** `pkg/httpclient/client.go:12`
- **Title:** Interface defined at the producer and stutters with the package name
- **Why it matters:** `httpclient.HTTPClientInterface` stutters (`httpclient.HTTPClient...`), carries an `Interface` suffix Go doesn't use, and is declared next to its only implementation. Idiomatic Go defines the small interface where it's consumed.
- **Recommendation:** Drop the interface here and return the concrete `*Client`. If a consumer needs to abstract it, let that consumer declare the one or two methods it actually uses (e.g. `type doer interface { Do(*http.Request) (*http.Response, error) }`).
- **Confidence:** high

## Good example — Consistency clearly labeled (suggestion)

- **File:** `internal/feed/feed.go:21,47`
- **Title:** File mixes nil-slice and empty-literal forms for the same purpose
- **Why it matters:** Line 21 uses `var items []Item`, line 47 uses `items := []Item{}` for the same "start empty" intent. They behave identically; the variety is noise that makes the file read as if the two cases differ.
- **Recommendation:** Use the nil-slice form `var items []Item` in both spots (canonical form in `consistency.md`). Strong default, not a hard rule.
- **Confidence:** medium

## Good example — Design question handed off

- **File:** `internal/billing/calculator.go:8`
- **Title:** Strategy interface may be premature
- **Why it matters:** `PricingStrategy` has one implementation and one caller; the indirection adds a layer without a second strategy in sight.
- **Recommendation:** Inline the concrete type for now; introduce the interface when the second pricing model actually lands.
- **Confidence:** medium
- → `/go-expert Should pricing variation be modeled as a strategy interface now, or deferred until a second pricing model exists?`

## Bad example

> Naming could be better and you should probably handle that error.

Why this is bad:
- no file/line
- no explanation of impact
- no concrete idiomatic fix
- no severity, no confidence
