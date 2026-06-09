# Idioms, API Design & Naming Review Rules

Grounded in *Effective Go*, *Go Code Review Comments*, the Google Go Style Guide, and the Uber Go Style Guide. These are how idiomatic Go reads. Deviation needs a reason.

## 1. Naming

### Hard rules

- Use `MixedCaps` / `mixedCaps`, never `snake_case` or `SCREAMING_SNAKE_CASE` — including constants (`MaxRetries`, not `MAX_RETRIES`).
- Exported = capitalized, unexported = lowercase. Export the minimum.
- Initialisms keep uniform case: `ID`, `URL`, `HTTP`, `API`, `DB`. Write `userID`, `ServeHTTP`, `xmlHTTPRequest` — never `userId`, `ServeHttp`, `Url`.
- No stutter. In package `http`, name it `Server`, not `HTTPServer` (callers write `http.Server`). Don't repeat the package name in its identifiers.
- No `Get` prefix on getters: `user.Name()`, not `user.GetName()`. Use a verb prefix only for expensive/effectful operations (`Fetch`, `Compute`).
- Identifier length scales with scope: `i`, `r`, `b` for tight scopes; descriptive names for package-level and exported names. (Pike: the right length is proportional to the distance between declaration and use.)

### Common weak names to flag

- `Manager`, `Helper`, `Util`/`Utils`, `Processor`, `Handler` (when not an actual handler), `Data`, `Info`, `Object`, `base`, `common`, `misc`.

### Review questions

- Would a reader predict this method's behavior from its name and the package it lives in?
- Does the name describe the domain, or the mechanism?

## 2. Packages

### Hard rules

- Package names are short, lowercase, single words, no underscores, no plurals: `time`, `bytes`, `httputil` — not `utils`, `helpers`, `common`, `base`, `models`.
- A package is a cohesive unit with a clear purpose, not a grab-bag. If you can't name it after what it does, the boundary is wrong.
- Package comment lives immediately above `package x`, starts with `Package x ...`, no blank line between.

### Review questions

- Is this a "junk drawer" package that exists only to hold loosely related functions?
- Does the import path read well at the call site?

## 3. Errors as values

### Hard rules

- Errors are values, returned as the last return value, handled explicitly. No exceptions, no panics for normal failure.
- Error strings: lowercase, no trailing punctuation (`"connect to db: timeout"`), because they compose into larger messages.
- Add context as the error travels up: `fmt.Errorf("load config %q: %w", path, err)`. Wrap with `%w` to preserve the chain.
- Sentinel errors (`var ErrNotFound = errors.New(...)`) are part of your API — name them `ErrXxx` and document them. Compare with `errors.Is`.
- Custom error types end in `Error` (`type ValidationError struct{}`); extract with `errors.As`.

### Strong defaults

- Prefer wrapping with context over bare `return err` when the call site adds information the caller can't infer.
- Don't over-wrap: one layer of context per boundary, not per call.

### Review questions

- Can a caller distinguish the failure modes it needs to, via `Is`/`As`?
- Does the wrapped message duplicate information already in the wrapped error?

## 4. Interfaces

### Hard rules

- Define interfaces where they are **consumed**, not where the implementation lives. The consumer declares the small interface it needs.
- Keep interfaces small. "The bigger the interface, the weaker the abstraction." (Pike) One- and two-method interfaces are the norm.
- Don't create an interface "just in case" or solely to enable mocking before a second implementation exists. Add the interface when a real second caller/implementation appears.
- "Accept interfaces, return structs." Functions take the narrow interface they need and return concrete types so callers keep full access.

### Review questions

- Does this interface have exactly one implementation and one consumer? It may not need to exist yet.
- Is this interface defined in the producer package and re-implemented for tests only? Move it to the consumer.

## 5. Function & method shape

### Strong defaults

- Receiver names are short (1–2 letters), consistent across all methods of the type; never `this`/`self`/`me`.
- Be consistent about receiver type per type: if any method needs a pointer receiver, use pointer receivers for all of them. Use value receivers for small immutable values, pointer receivers when mutating, when the struct is large, or when it holds a non-copyable field.
- Prefer synchronous functions that return results directly over functions that take callbacks or spawn goroutines.
- Avoid named result parameters except when they meaningfully document the return or are needed for a deferred mutation; avoid naked returns in anything but tiny functions.

## 6. API surface & zero values

### Strong defaults

- Make the zero value useful where you can (`sync.Mutex`, `bytes.Buffer` need no constructor). If a type needs initialization, provide a `NewXxx` constructor and document that the zero value is not ready.
- Functional options (`WithTimeout(...)`) for constructors with many optional parameters, instead of long parameter lists or config structs full of zero-able fields — but don't reach for options when 1–2 params suffice.
- Return early; keep the happy path at the lowest indentation (line-of-sight). See `consistency.md`.

## 7. Documentation

### Hard rules

- Every exported identifier has a doc comment. It is a full sentence starting with the identifier name: `// Server handles incoming requests.`
- Document the behavior callers depend on: who closes returned resources, whether a method is safe for concurrent use, what the zero value means.

### Review questions

- Does the doc comment start with the name and read as a sentence?
- Are concurrency guarantees and ownership of returned resources stated?
