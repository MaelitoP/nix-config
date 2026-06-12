# Audit dimensions

Seven dimensions, each with grep-able markers and a "real vs noise" test. Sweep markers first, confirm by reading.

## 1. Comment bloat / narration

Markers: comment-to-code ratio per file (flag outliers), block comments > 15 lines, doc comments on private helpers, and prose tells: `gracefully`, `robust`, `seamlessly`, `leverage`, `ensure proper`, `for clarity`, `Note that`, `It's important to`, `This function`, `This method`, section banners (`====`, `----`, `# ---`).

Real vs noise: a comment stating a non-inferable constraint, invariant, external-bug workaround (with link), or counterintuitive business rule is real. Everything narrating, restating names, or addressing a reviewer is noise. A 190-line spec walkthrough is noise even when accurate — the fix is 10 lines plus a link.

## 2. Sleep-based test synchronization

Markers, in test files only (`*_test.go`, `test_*.py`, `*Test.php`, `*.spec.ts`, `*.test.js`, `tests/` dirs, `#[test]`/`#[tokio::test]` blocks):
- Go: `time.Sleep(`
- Python: `time.sleep(`, `asyncio.sleep(` outside the code under test
- PHP: `sleep(`, `usleep(`
- Rust: `thread::sleep(`, `tokio::time::sleep(`
- JS/TS: `setTimeout(` / `await new Promise(r => setTimeout` as a barrier

Real vs noise: a sleep inside a deadline-bounded polling helper (`eventually`, `waitUntil`, `wait_for`) is acceptable; a bare sleep followed by an assertion is slop — it trades determinism for wall-clock luck.

## 3. Test-only production exports

Markers: public/exported members whose only references are in test files; names or comments containing `test hook`, `for testing`, `used by tests`, `visible for testing`, `@VisibleForTesting`.

Real vs noise: cross-check references — if production code never calls it, it's API pollution. The fix is observing through a fake/double or the language's test-access idiom (`export_test.go`, `#[cfg(test)]`, package-private + test in package).

## 4. Defensive redundancy

Markers: `should never happen`, `just in case`, `defense in depth`, `defensive`, `sanity check`, `fallback` near re-validation; the same invariant checked at two layers; branches a comment admits are "not normally reached".

Real vs noise: a second check is real only when its failure mode is catastrophic-and-silent (data loss, corruption) and the comment says so. Otherwise validate once at the owning boundary and delete the echo.

## 5. Stylistic drift (multi-session generation fingerprint)

Markers: two idioms for one construct in one module — Go `interface{}` vs `any`, `fmt.Errorf` vs `errors.New` for static strings; Python f-string vs `.format` vs `%`; JS `'` vs `"` quoting, `function` vs arrow for the same role; PHP array() vs []; Rust `unwrap()` islands in `?`-style code.

Real vs noise: drift is noise by definition; the canonical form is whichever the file/module already uses most. Flag the minority occurrences.

## 6. Volume fingerprints

Markers: test:code line ratio per package/module (flag > ~3:1 for ordinary glue code — concurrency/parser code legitimately runs higher), near-duplicate test bodies (same structure, one literal changed, not table-driven), assertions that cannot fail, generated-looking boilerplate repeated instead of extracted.

Real vs noise: thoroughness on genuinely tricky logic is real; copies of the happy-path test with cosmetic variation are padding. Judge by what additional failure each test can catch.

## 7. Naming / prose tells

Markers: identifiers like `Enhanced`, `Improved`, `Smart`, `Helper2`, `NewV2`, `Utils` grab-bags; emoji in comments or commit-style headers in code; README/doc sections that read like marketing ("blazingly fast", "production-ready", "battle-tested"); apologetic hedging in comments ("this is a bit hacky but").

Real vs noise: one tell is cosmetic; clusters of them mark files generated without review — read those files more suspiciously across all other dimensions.
