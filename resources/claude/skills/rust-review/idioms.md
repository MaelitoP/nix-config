# Idioms, API Design & Naming Review Rules

Grounded in the *Rust API Guidelines* (the `C-*` items), *Effective Rust*, *Rust for Rustaceans*, and the Clippy idiom lints. These are how idiomatic Rust reads. Deviation needs a reason.

## 1. Naming

### Hard rules

- Casing per RFC 430 (`C-CASE`): `snake_case` for functions, methods, variables, modules, and crates; `CamelCase` for types, traits, and enum variants; `SCREAMING_SNAKE_CASE` for constants and statics.
- Conversion methods follow cost/ownership conventions (`C-CONV`):
  - `as_` — cheap, borrowed→borrowed, no allocation (`str::as_bytes`).
  - `to_` — expensive, borrowed→owned, allocates (`str::to_string`, `Path::to_owned`).
  - `into_` — by value, owned→owned, consumes `self` (`String::into_bytes`).
- Getters have no `get_` prefix (`C-GETTER`): `fn name(&self) -> &str`, not `get_name`. (`get_` is reserved for the `get`/`get_mut` indexing idiom on collections.)
- Iterator producers are named `iter` / `iter_mut` / `into_iter` (`C-ITER`); the returned iterator type's name matches the method (`C-ITER-TY`).
- Names use consistent word order across the crate (`C-WORD-ORDER`): pick `verb_noun` or `noun_verb` and stay with it.

### Common weak names to flag

- `Manager`, `Helper`, `Util`/`Utils`, `Processor`, `Handler` (when not an actual handler), `Data`, `Info`, `Object`, `common`, `misc`, `base`, `stuff`.
- A `mod utils`/`mod common`/`mod helpers` is almost always a cohesion failure.

### Review questions

- Would a reader predict this method's behavior from its name and the type it's on?
- Does the name describe the domain, or the mechanism?
- Does a conversion's prefix (`as_`/`to_`/`into_`) match its actual cost and ownership?

## 2. Modules & visibility

### Hard rules

- Default to private. `pub` is an API commitment — export the minimum (`C-STRUCT-PRIVATE`, *Effective Rust* Item 22: minimize visibility). Prefer `pub(crate)`/`pub(super)` over blanket `pub` for internal sharing.
- Structs have private fields unless they are plain data with no invariant (`C-STRUCT-PRIVATE`). Public fields freeze the layout into your API and skip validation.
- Re-export dependency types that appear in your public API so callers don't need to add the dependency themselves (`C-STABLE`, *Effective Rust* Item 24).
- No wildcard imports (`use foo::*`) outside a prelude or test module (*Effective Rust* Item 23).

### Review questions

- Is this a "junk drawer" module that exists only to hold loosely related items?
- Does a `pub` item actually need to be public, or would `pub(crate)` do?

## 3. Errors

### Hard rules

- Functions that can fail return `Result<T, E>`; propagate with `?`. Don't `panic!`/`unwrap`/`expect` for recoverable failure (*Effective Rust* Item 18; see `correctness-concurrency.md`).
- Error types are meaningful and well-behaved (`C-GOOD-ERR`): implement `std::error::Error` and `Display`, expose `source()` for the cause chain, and be `Send + Sync + 'static` so they cross threads and box cleanly.
- Error `Display` messages are lowercase, no trailing punctuation — they compose into larger messages.

### Strong defaults

- **Libraries:** define a concrete error `enum` and derive it with `thiserror`. Callers can `match` on variants. Don't expose `anyhow::Error` (or `Box<dyn Error>`) as a library's public error — it erases the variants callers need.
  ```rust
  #[derive(Debug, thiserror::Error)]
  pub enum LoadError {
      #[error("read config {path}")]
      Read { path: PathBuf, #[source] source: std::io::Error },
      #[error("parse config")]
      Parse(#[from] toml::de::Error),
  }
  ```
- **Binaries / applications:** use `anyhow` (or `eyre`) with `?` and `.context("doing X")`. One opaque error type with a context chain is right when nobody needs to match.
- Mark important results `#[must_use]` (it's implicit on `Result`, but add it to custom "you must handle this" return types).
- Use `#[from]` to let `?` convert at boundaries; don't hand-write `map_err` where a `From` impl is the idiom.

### Review questions

- Can a caller distinguish the failure modes it needs to, by matching on the error?
- Does a library function leak `anyhow::Error` into its public signature?
- Does the wrapped/context message duplicate information already in the source?

## 4. Traits & conversions

### Hard rules

- Types eagerly implement the common traits (`C-COMMON-TRAITS`): `Debug` on every public type (`C-DEBUG`), and `Clone`, `PartialEq`, `Eq`, `Hash`, `PartialOrd`, `Ord`, `Default`, `Copy` where they make sense. Prefer `#[derive(...)]`.
- Conversions use the standard traits (`C-CONV-TRAITS`): `From`/`Into` (infallible), `TryFrom`/`TryInto` (fallible), `AsRef`/`AsMut` (cheap reference). Implement `From`, get `Into` for free — don't implement `Into` directly.
- Don't add inherent methods to smart pointers (`C-SMART-PTR`); only smart pointers implement `Deref`/`DerefMut` (`C-DEREF`). `Deref`-abuse to fake inheritance is a finding.
- Constructors are static inherent methods, conventionally `Self::new` (`C-CTOR`).

### Strong defaults

- Keep traits object-safe if they're plausibly useful as `dyn Trait` (`C-OBJECT`).
- Use default method implementations to keep the required trait surface small (*Effective Rust* Item 13).
- Seal traits you don't want downstream crates to implement (`C-SEALED`) when the trait is an implementation detail of an enum-like set.

### Review questions

- Does a public type derive `Debug`? (Missing `Debug` is a finding — `C-DEBUG`.)
- Is a conversion hand-rolled as a method where `From`/`TryFrom` is the idiom?
- Is `Deref` used to simulate inheritance rather than for a genuine smart pointer?

## 5. Function & method shape

### Strong defaults

- Accept the most general borrowed input; let the caller control placement (`C-CALLER-CONTROL`): `&str` over `&String`, `&[T]` over `&Vec<T>`, `impl AsRef<Path>` for paths, `impl IntoIterator<Item = T>` for sequences, `R: Read`/`W: Write` by value for streams.
- Take ownership only when you store the value; otherwise borrow.
- Functions don't take out-parameters (`C-NO-OUT`) — return a value or a tuple/struct instead.
- Functions with a clear receiver are methods (`C-METHOD`); free functions are for things that don't belong to one type.
- Minimize assumptions with generics, but don't over-genericize (`C-GENERIC` vs *Effective Rust* Item 20). A monomorphization explosion or an unreadable bound is a cost.
- Validate arguments and return `Err` (or use a newtype that can't hold an invalid value) — `C-VALIDATE`.

## 6. Type safety: newtypes, builders, flags

### Strong defaults

- Newtypes provide static distinctions and encapsulate invariants (`C-NEWTYPE`, `C-NEWTYPE-HIDE`, *Effective Rust* Item 6). Use them for domain values (`UserId`, `Meters`) and to make illegal states unrepresentable. A bare `type` alias gives no safety.
- Arguments convey meaning through types, not `bool`/`Option` positional flags. Two `bool` params at a call site are unreadable; use an enum or distinct methods.
- Use the `bitflags` crate for flag sets, not hand-rolled enums (`C-BITFLAG`).
- Builders for complex/optional construction (`C-BUILDER`, *Effective Rust* Item 7); a typestate builder can make "incomplete" unrepresentable. For 1–3 required args, prefer a plain `new` constructor.

## 7. Iterators & expressions

### Strong defaults

- Prefer iterator transforms over explicit index loops where they read clearly (`.filter().map().collect()`, `.sum()`, `.any()`, `.find()`) — *Effective Rust* Item 9. They're idiomatic and zero-cost.
- Prefer `Option`/`Result` combinators over `match` for simple transforms (`.map`, `.and_then`, `.ok_or`, `.unwrap_or_default`, `?`) — *Effective Rust* Item 3. Keep `match` for arms with real logic.
- Don't `collect()` just to iterate again; chain the iterator.

## 8. Documentation

### Hard rules

- Public items have doc comments (`///`) — *Effective Rust* Item 27, `C-EXAMPLE`. Crate-level docs (`//!`) are thorough with examples (`C-CRATE-DOC`).
- Examples in docs use `?`, never `unwrap`/`try!` (`C-QUESTION-MARK`). Doctests compile and run, so they double as tests.
- Document the conditions: a `# Errors` section for what `Err` means, a `# Panics` section for any panic, a `# Safety` section for every `unsafe fn` (`C-FAILURE`).
- Hide implementation noise from rustdoc (`#[doc(hidden)]`, `C-HIDDEN`).

### Review questions

- Does a public item have a doc comment with a runnable example?
- Does a fallible/panicking/`unsafe` function document `# Errors`/`# Panics`/`# Safety`?
