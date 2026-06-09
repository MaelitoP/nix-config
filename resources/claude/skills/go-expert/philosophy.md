# Go Philosophy & Proverbs

The principles that ground every recommendation. Sources: Rob Pike, *Go Proverbs* (Gopherfest 2015); Dave Cheney, *The Zen of Go* (2020) and *Practical Go* (GopherCon Israel 2019); *Effective Go*; the Go blog. Cite these by name when advising.

## The overriding value: simplicity and clarity

- **"Clear is better than clever."** (Cheney) Optimize for the reader. The person maintaining this code — possibly you in a year — should grasp it without unpacking cleverness.
- **"Simplicity is complicated."** (Pike) A simple interface often hides hard work; that work belongs *inside* the package, not pushed onto every caller.
- **Readability is the point.** Go deliberately has one formatting (`gofmt`), few keywords, and limited expressiveness so that all Go reads the same way. Uniformity is a feature; novelty in spelling is a cost. This is the basis for the single-syntax consistency rules.
- **"Flat is better than nested."** (Zen of Go) Guard clauses and early returns keep the happy path on the left margin (line-of-sight). Deep nesting hides logic.

## The Go Proverbs (Pike) — the ones that decide designs

- **"Don't communicate by sharing memory; share memory by communicating."** Prefer passing data over a channel to sharing it behind a lock — when it's the simpler model. (But see Cheney below: don't be dogmatic.)
- **"Concurrency is not parallelism."** Concurrency is structuring a program as independently executing pieces; parallelism is doing many things at once. Go gives you the first; the runtime may give you the second. Design for clean structure, not for "speed".
- **"Channels orchestrate; mutexes serialize."** Use channels to coordinate ownership and flow; use a mutex to protect a small critical section. Each has its place — the standard library uses both.
- **"The bigger the interface, the weaker the abstraction."** Small interfaces (`io.Reader`, `io.Writer`) compose and are easy to implement. Wide interfaces couple callers to too much.
- **"Make the zero value useful."** `sync.Mutex`, `bytes.Buffer`, and `time.Time` need no constructor. Design types so their zero value is ready, or document clearly that it isn't.
- **"interface{} says nothing."** (Now `any` — same point.) Empty interfaces discard type information; reach for them only at genuine boundaries (serialization, `fmt`), not as a default parameter type.
- **"Errors are values."** Errors are ordinary values you program with — inspect, wrap, compare, and store them. They are not exceptional control flow.
- **"Don't just check errors, handle them gracefully."** A bare `if err != nil { return err }` everywhere is a smell; add context, decide, or recover meaningfully.
- **"A little copying is better than a little dependency."** Copying a few lines can be cleaner than importing a package (or adding an interface) to share them. Coupling has a cost.
- **"Design the architecture, name the components, document the details."** In that order.
- **"Gofmt's style is no one's favorite, yet gofmt is everyone's favorite."** Uniformity beats personal preference. The same logic applies to the choices `gofmt` leaves open.

## The Zen of Go (Cheney) — the engineering rules

1. Each package fulfills a single purpose. (Cohesion; no junk-drawer packages.)
2. Handle errors explicitly. (No silent failures, no panics for normal flow.)
3. Return early rather than nesting deeply.
4. Leave concurrency to the caller. (Libraries expose synchronous APIs; callers decide how to run them.)
5. Before you start a goroutine, know when — and whether — it will stop.
6. Avoid package-level state. (It couples otherwise independent code and breaks tests.)
7. Simplicity matters. (Prefer the obvious solution.)
8. Write tests to lock in the behavior of your package's public API.
9. If you think it's slow, prove it with a benchmark. (Don't guess at performance; `testing.B` and `pprof` decide. "In the face of ambiguity, refuse the temptation to guess.")
10. Moderation is a virtue. (Use goroutines, channels, generics, reflection, and embedding sparingly and deliberately.)

## Practical heuristics worth quoting

- **Identifier length scales with scope.** (Pike) Short names (`i`, `r`, `b`) in tight scopes; descriptive names for exported, long-lived, or distant identifiers. The right length is proportional to the distance between declaration and use.
- **Accept interfaces, return structs.** Take the narrow behavior you need; hand back a concrete type so the caller keeps full access.
- **Define interfaces at the point of use.** The consumer declares the small interface it needs; the producer just returns its concrete type. This avoids premature abstraction and import cycles.
- **A function that starts a goroutine should make its lifetime explicit** — return something to wait on, or accept a `context` to cancel it. Don't hide concurrency from the caller.
- **Don't be dogmatic about channels.** Cheney's caution: channels are not always the answer. A `sync.Mutex` around a small struct is often clearer and faster than a channel-based actor. Choose the simpler model for the specific problem.

## Standard-library precedents to cite

These usually end a debate — point at the canon:

- Small interfaces: `io.Reader`, `io.Writer`, `io.Closer`, `fmt.Stringer`, `sort.Interface`.
- Useful zero values: `sync.Mutex`, `bytes.Buffer`, `time.Time`, `strings.Builder`.
- Functional options: `grpc.Dial(..., opts ...DialOption)`, much of `crypto/tls`.
- Errors as values & wrapping: `errors.Is`/`errors.As`/`%w`, `fs.ErrNotExist`, `sql.ErrNoRows`.
- Context as first arg: nearly every blocking stdlib call added since 1.7 (`http.Request.WithContext`, `database/sql`'s `*Context` methods).
- Constructor only when needed: `bytes.Buffer` has none; `http.Client` has a useful zero value; `bufio.NewReader` exists because the zero value isn't ready.
