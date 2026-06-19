# Single-Syntax Consistency Rules

This is the "one way to do things" doc. Rust is uniform by design (`rustfmt` removed formatting debates, Clippy nudges idiom); this file extends that uniformity to the choices the tools leave open. When the same thing can be written two ways, **pick the canonical form below** and flag deviations. The goal is to remove noise so readers spend attention on logic, not on incidental variety.

These are **opinionated strong defaults**, not hard language rules. Flag a deviation as a `Suggestion` and name the canonical form. Allow a deviation only when there is a concrete local reason, and say so. Many of these are also Clippy lints — when Clippy already flags it, cite the lint instead of restating it.

## How to apply

For each rule: the canonical form is on the left, the discouraged variant on the right. A diff that introduces the discouraged form — or a file that uses both forms for the same purpose — is a finding. Mixing forms within one file is worse than either form used consistently; call that out specifically.

## 1. Matching one variant

| Canonical | Avoid |
|---|---|
| `let Some(x) = opt else { return };` (early exit) | a `match` with a trivial `None => return` arm |
| `if let Some(x) = opt { ... }` (one arm, no else logic) | `match opt { Some(x) => ..., None => () }` |
| `opt.map(\|x\| ...)` / `.and_then` / `.unwrap_or_default()` | a `match` that only transforms the value |
| `match` (2+ meaningful arms) | a chain of `if let ... else if let ...` |

- Use a combinator for a pure transform; use `match` when arms carry real logic; use `let else` to bind-or-bail and keep the happy path unindented.

## 2. Error propagation

- Use `?` to propagate. Don't hand-write `match res { Ok(v) => v, Err(e) => return Err(e.into()) }` — that's exactly what `?` does.
- Convert error types at the boundary via `#[from]`/`From` so `?` just works; reach for `.map_err(...)` only when adding context the `From` impl can't.
- In binaries, `.context("…")?` (anyhow/eyre). In libraries, return the concrete error variant.

## 3. `unwrap` / `expect` / panic

- Production paths: no `unwrap`/`expect` on values that can be `None`/`Err` from real input. Use `?`, `unwrap_or`, `unwrap_or_else`, `unwrap_or_default`, or a real error.
- When a panic is genuinely a "can't happen" invariant, prefer `expect("reason it can't happen")` over bare `unwrap()` so the message documents the invariant. (Tests may `unwrap` freely.)

## 4. String formatting

- Use inline captured identifiers: `format!("{name}: {count}")`, not `format!("{}: {}", name, count)` when the args are plain identifiers (Clippy `uninlined_format_args`). Keep positional/explicit args only for expressions or repositioning.
- `{x:?}` for `Debug`, `{x}` for `Display`. Don't hand-build a debug string when `{:?}`/`{:#?}` exists.
- Don't concatenate with `+` and `to_string()` where `format!` reads better; don't `format!` a single value where `.to_string()` suffices.

## 5. Collection & value construction

| Canonical | Avoid |
|---|---|
| `Vec::new()` / `vec![]` for empty | `Vec::with_capacity(0)` |
| `vec![a, b, c]` | `let mut v = Vec::new(); v.push(...)` ×3 |
| `HashMap::from([(k, v), ...])` / `.collect()` | repeated `insert` for a fixed literal map |
| `T::default()` / `#[derive(Default)]` | hand-written all-zero constructor |
| `.collect::<Vec<_>>()` (turbofish on the method) | type-annotating a throwaway binding just to steer `collect` |

- Pick one of turbofish (`collect::<Vec<_>>()`) vs binding annotation (`let v: Vec<_> =`) per file and stay consistent.

## 6. Binding & mutability

| Canonical | Avoid |
|---|---|
| `let x = ...;` immutable by default | `let mut x` when never reassigned (Clippy will flag) |
| shadowing for a type/representation change (`let n = s.parse()?;`) | a second differently-named temp for the same concept |
| `if cond { a } else { b }` as an expression | a `let mut x; if cond { x = a } else { x = b }` |

## 7. References & clones

- Don't `.clone()` to escape the borrow checker reflexively — borrow, restructure, or take ownership deliberately. A clone in a hot path or loop is a finding (often Clippy `redundant_clone`).
- `&x` over `x.clone()` when the callee only needs a borrow. `.to_owned()`/`.to_string()` only when you must store the value.
- Don't write `&Vec<T>`/`&String` parameters — use `&[T]`/`&str` (Clippy `ptr_arg`).

## 8. Control flow & line of sight

- Return early / `let else` early; keep the happy path at the lowest indentation. Avoid `else` after a block that returns.
- Avoid more than 2–3 levels of nesting; extract a function or use combinators. Deep `match`/`if let` pyramids are a finding.
- `?` over nested `match`; iterator chains over nested loops where they read clearly.

## 9. Imports & grouping

- Let `rustfmt` group and order imports; don't hand-fight it. Group `std`, external crates, then `crate`/`self`/`super` (rustfmt's `imports_granularity`/`group_imports` if the project sets it).
- No glob imports (`use x::*`) outside a `prelude` or `#[cfg(test)]` module.
- Don't rename imports (`as`) unless there's a real name collision.

## 10. Enums & exhaustiveness

- Model a closed set of states as an `enum`, matched exhaustively — don't add a catch-all `_ => ...` that silently swallows a future variant when you want the compiler to force you to handle it.
- Use `#[non_exhaustive]` on public enums/structs that may grow, so downstream `match` keeps compiling — but then internal matches still handle every known variant explicitly.

## 11. Lints & attributes

- One convention for lint posture: prefer crate-level `#![warn(...)]`/`#![deny(...)]` over scattering `#[allow(...)]`. Every `#[allow(...)]` on a Clippy/compiler lint should carry a one-line reason, or it's a finding.
- Don't sprinkle `#[allow(dead_code)]` to silence the compiler instead of deleting unused code.

## Review wording

When you flag a consistency issue, say:
- which canonical form applies,
- that it is a strong default (not a hard rule), and the Clippy lint name if one exists,
- and whether the file mixes forms (mixing is the stronger finding).

Example: "Suggestion — this transforms an `Option` with a 2-arm `match` (line 30) where a combinator is canonical: `opt.map(|x| x + 1).unwrap_or(0)`. Clippy flags adjacent cases as `manual_map`. Strong default, not a hard rule."
