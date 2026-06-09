# Single-Syntax Consistency Rules

This is the "one way to do things" doc. Go is uniform by design (`gofmt` removed formatting debates); this file extends that uniformity to the choices `gofmt` leaves open. When the same thing can be written two ways, **pick the canonical form below** and flag deviations. The goal is to remove noise so readers spend attention on logic, not on incidental variety.

These are **opinionated strong defaults**, not hard language rules. Flag a deviation as a `Suggestion` and name the canonical form. Allow a deviation only when there is a concrete local reason, and say so.

## How to apply

For each rule: the canonical form is on the left, the discouraged variants on the right. A diff that introduces the discouraged form — or a file that uses both forms for the same purpose — is a finding. Mixing forms within one file is worse than either form used consistently; call that out specifically.

## 1. Variable declaration

| Canonical | Avoid |
|---|---|
| `x := f()` for locals with a value | `var x = f()` for locals |
| `var x int` / `var buf bytes.Buffer` for zero-value locals | `x := 0`, `x := ""` just to get a zero value |
| `var s []T` (nil slice) for an empty slice | `s := []T{}` |
| `m := make(map[K]V)` | `var m map[K]V` then writing to it (nil-map panic) |

- Use `:=` when initializing with a real value; use `var` when you want the zero value or are declaring without init.
- Package-level declarations always use `var`/`const` (no `:=` at package scope — it's not legal anyway).

## 2. Empty / nil collections

- Prefer the **nil slice** `var s []T` over `[]T{}`. They behave identically for `len`, `range`, and `append`; nil is the idiomatic "no elements yet".
- Exception: when marshaling to JSON and the consumer requires `[]` rather than `null`, use `[]T{}` and note why.

## 3. `any` vs `interface{}`

- Use `any`. `interface{}` is the same type but `any` (Go 1.18+) is the standard, more readable spelling. Flag new `interface{}`.

## 4. String formatting verbs

- `%v` for general values, `%q` for quoted strings (handles empty/control chars), `%d` for integers, `%w` for wrapping errors, `%T` for types, `%+v`/`%#v` for debugging structs.
- Don't hand-quote: use `%q`, not `"\"" + s + "\""` or `fmt.Sprintf("'%s'", s)`.
- Use `%s` for a plain string/`Stringer`, `%v` when the value might be anything. Be consistent within a file.

## 5. Error construction

| Situation | Canonical |
|---|---|
| Static message, no args | `errors.New("message")` |
| Formatted message | `fmt.Errorf("...: %v", x)` |
| Wrapping a cause | `fmt.Errorf("...: %w", err)` |
| Sentinel | `var ErrXxx = errors.New("...")` at package scope |

- Don't use `fmt.Errorf` with no formatting verbs — use `errors.New`.
- Error strings: lowercase, no trailing period.

## 6. Indent-error-flow (line of sight)

Canonical — handle the error and return; keep the happy path unindented:

```go
f, err := os.Open(name)
if err != nil {
    return err
}
// use f
```

Avoid wrapping the success path inside the `if`:

```go
if err == nil {
    // use f      // discouraged: happy path indented, error path trailing
} else {
    return err
}
```

- No `else` after a block that returns/breaks/continues. Return early.
- Avoid more than 2–3 levels of nesting; extract a function instead. "Flat is better than nested." (Zen of Go)

## 7. Struct literals

- Use **keyed** fields: `User{Name: "a", Age: 3}`, not positional `User{"a", 3}` — required for structs from other packages, strongly preferred for your own (survives field reordering/additions).
- Omit zero-value fields rather than writing them explicitly, unless their presence documents intent.

## 8. Loops & iteration

- `for i := range n` (Go 1.22+ integer range) or `for i := 0; i < n; i++` — pick one form per codebase for counted loops.
- `for k, v := range m` / `for i, v := range s`; drop unused range variables (`for range s {}`, `for k := range m {}`) rather than naming them `_` when both are unused.

## 9. Receiver consistency

- One receiver style per type: if any method has a pointer receiver, all do. Don't mix `func (s S)` and `func (s *S)` on the same type.
- Same short receiver name across every method of the type.

## 10. Imports & grouping

- Let `goimports` group: stdlib first, then third-party/local, separated by a blank line. Don't hand-order against the tool.
- Don't rename imports unless there's a genuine collision; a renamed import is a finding when an unaliased one would compile.

## 11. Constructors & "New"

- One constructor convention: `NewT(...) *T` (or `NewT(...) (T, error)` when construction can fail). Don't mix `NewT`, `MakeT`, `CreateT`, `BuildT` for the same role in one package.

## 12. Comparisons & booleans

- `if b {` not `if b == true {`; `if !b {` not `if b == false {`.
- Compare to nil/zero directly; don't write `len(s) == 0` when you mean "empty" inconsistently with the rest of the file — pick one of `len(s) == 0` vs `s == nil` per intended meaning (they differ; choose deliberately).

## 13. Enums

- Use a defined type plus `iota` constants, one canonical pattern per package: `type State int; const (StatePending State = iota; StateActive; ...)`. Implement `String()` for them. Don't mix bare-string enums and typed-int enums for the same concept.

## Review wording

When you flag a consistency issue, say:
- which canonical form applies,
- that it is a strong default (not a hard rule),
- and whether the file mixes forms (mixing is the stronger finding).

Example: "Suggestion — this file declares empty slices both as `[]T{}` (line 12) and `var s []T` (line 40). Prefer the nil-slice form throughout; pick one. Strong default, not a hard rule."
