# Rust Philosophy & Principles

The principles that ground every recommendation. Sources: the *Rust API Guidelines* (rust-lang library team), *Effective Rust* (David Drysdale), *Rust for Rustaceans* (Jon Gjengset), *Programming Rust* (Blandy/Orendorff/Tindall), the Clippy lints, and the writing of matklad (Aleksey Kladov), BurntSushi (Andrew Gallant), and Niko Matsakis. Cite these by name when advising.

## The overriding value: encode correctness in types

- **Make illegal states unrepresentable.** Choose data structures so that a value that exists is, by construction, valid. An `enum` that lists the only legal states beats a struct of `bool`s and `Option`s whose invalid combinations you must remember to guard. (*Effective Rust* Item 1: use the type system to express your data structures.)
- **Parse, don't validate.** Validate once at the boundary and return a *more precise type* (a newtype, a non-empty vec, a parsed struct) so the rest of the program can't re-encounter the invalid case. (Alexis King's principle, deeply idiomatic in Rust.)
- **Newtypes give static distinctions for free.** `struct UserId(u64)` and `struct OrderId(u64)` can't be swapped at a call site; a raw `u64` can. (`C-NEWTYPE`, *Effective Rust* Item 6.)
- **Arguments convey meaning through types, not `bool`/`Option`.** `open(path, /* write */ true, /* create */ false)` is unreadable; a flags type or distinct methods is self-documenting. (API Guidelines.)

## Ownership and borrowing as a design tool

- **Ownership models lifetime and responsibility.** Who owns a value answers "who frees it, who may mutate it". Design APIs around that question first.
- **Accept borrows, return owned.** Take the most general borrowed form (`&str`, `&[T]`, `impl AsRef<Path>`); return concrete owned types so the caller keeps full access. The caller decides where data is copied and placed (`C-CALLER-CONTROL`).
- **Let the borrow checker shape the design.** Fighting the borrow checker usually signals a shared-ownership question you haven't answered — reach for `Rc`/`Arc`, a redesign, or an index/handle, not for `unsafe`. (*Effective Rust* Items 14–15.)
- **RAII: resources release in `Drop`.** Tie a resource's lifetime to a value; cleanup happens deterministically when it goes out of scope. Destructors must not fail (`C-DTOR-FAIL`) and should not block without an alternative (`C-DTOR-BLOCK`). (*Effective Rust* Item 11.)

## Errors are values, not exceptions

- **Return `Result`, propagate with `?`.** Errors are ordinary values you program with — match on them, map them, add context. They are not control flow you throw. (*Effective Rust* Item 4.)
- **Don't panic for ordinary failure.** `panic!`/`unwrap`/`expect` abort the thread (and often the process). Reserve them for genuinely-unreachable invariants and tests. A library that panics on bad input is a library that crashes its callers. (*Effective Rust* Item 18.)
- **Library errors are concrete and meaningful; application errors are contextual.** Libraries: a `thiserror`-derived enum implementing `std::error::Error`, so callers can match (`C-GOOD-ERR`). Applications: `anyhow`/`eyre` with `.context(...)`. Never leak `anyhow::Error` from a library's public surface.
- **Prefer `Option`/`Result` combinators over explicit `match` for simple transforms.** `.map`, `.and_then`, `.ok_or`, `.unwrap_or_default`, `?` read better than a three-arm `match` that just shuffles the value. (*Effective Rust* Item 3.) Use `match` when the arms carry real logic.

## Zero-cost abstractions and "don't pay for what you don't use"

- **Abstractions compile away.** Iterators, generics, and `Option` are designed to be as fast as the hand-written loop. Prefer iterator transforms over manual index loops — they're clearer *and* the optimizer handles them. (*Effective Rust* Item 9.)
- **Generics for static dispatch; `dyn` when you need it.** Monomorphized generics are zero-cost but grow code size; trait objects add a vtable indirection but stay flexible and small. Choose deliberately. (*Effective Rust* Item 12.)
- **Don't over-optimize.** Reach for clarity first; prove a hot path with a benchmark (`criterion`) before contorting the code. (*Effective Rust* Item 20.)

## Fearless concurrency

- **`Send`/`Sync` are the compiler's data-race proof.** The type system prevents data races at compile time — share state only through types that say it's safe (`Arc`, `Mutex`, atomics, channels). (*Programming Rust*; *Effective Rust* Item 17: be wary of shared-state parallelism.)
- **Prefer message passing where there's a clear owner; a mutex for small shared state.** Channels move ownership and orchestrate; a `Mutex` guards a short critical section. Don't force a channel where a mutex is plainly simpler.
- **Async colors your API.** `async fn` is contagious and introduces cancellation as a first-class concern. Leave concurrency to the caller where you can; keep libraries runtime-agnostic when feasible. (See `../rust-review/async.md`.)

## Traits, conversions, and the common-traits habit

- **Implement the common traits eagerly.** `Debug` on every public type (`C-DEBUG`), plus `Clone`, `PartialEq`, `Eq`, `Hash`, `Default`, `Copy`, `Ord` where they make sense (`C-COMMON-TRAITS`). Downstream code and `derive`s depend on them.
- **Conversions use the standard traits.** `From`/`Into` for infallible, `TryFrom`/`TryInto` for fallible, `AsRef`/`AsMut` for cheap reference conversion (`C-CONV-TRAITS`). Implement `From`, get `Into` free. Name ad-hoc conversions `as_`/`to_`/`into_` by cost and ownership (`C-CONV`).
- **Default-implement trait methods to minimize the required surface.** (*Effective Rust* Item 13.)
- **Know the standard traits before inventing your own.** (*Effective Rust* Item 10.)

## Tooling is part of the language

- **Listen to Clippy.** Its lints encode community idiom; a Clippy warning is a finding, not noise. (*Effective Rust* Item 29.)
- **`rustfmt` ends formatting debates.** Like `gofmt`: uniformity beats preference. Never hand-fight the formatter.
- **Write more than unit tests.** Doctests document *and* verify (`C-EXAMPLE`); integration tests exercise the public API; `proptest` finds edge cases. (*Effective Rust* Item 30.)
- **Minimize visibility and dependencies.** `pub` is an API commitment (`C-STRUCT-PRIVATE`); every dependency is a liability (*Effective Rust* Items 22, 25, 26).

## Precedents to cite

These usually end a debate — point at the canon:

- Borrowed-input signatures: `std::io::Read`/`Write` take `&mut self`; `Path::new` takes `impl AsRef<OsStr>`; `str::contains` over `&String`.
- Newtypes for safety: `std::time::Duration`, `std::num::NonZeroU32`, `std::path::PathBuf`.
- Builders: `std::process::Command`, `std::thread::Builder`.
- Conversion traits: `String: From<&str>`, `Vec<T>: FromIterator<T>`, `?` relying on `From` for error conversion.
- Errors as values: `std::io::Error` (kind + source), `std::num::ParseIntError`; `?` and the `From` chain.
- Useful `Default`: `String`, `Vec`, `HashMap`, most config structs via `#[derive(Default)]`.
- Iterators over loops: `.iter().filter().map().collect()` as the canonical transform pipeline.
