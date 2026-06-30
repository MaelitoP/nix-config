# Single-Syntax Consistency Rules

This is the "one way to do things" doc — the Zen of Python's "there should be one obvious way" applied to review. A formatter (`ruff format` / Black) removes layout debates; this file extends that uniformity to the choices the formatter leaves open. When the same thing can be written two ways, **pick the canonical form below** and flag deviations. The goal is to remove noise so readers spend attention on logic, not on incidental variety.

These are **opinionated strong defaults**, not hard language rules. Flag a deviation as a `Suggestion` and name the canonical form. Allow a deviation only when there is a concrete local reason, and say so. Many of these are also Ruff lints — when Ruff already flags it, cite the rule code instead of restating it.

## How to apply

For each rule: the canonical form is on the left, the discouraged variant on the right. A diff that introduces the discouraged form — or a file that uses both forms for the same purpose — is a finding. Mixing forms within one file is worse than either form used consistently; call that out specifically.

## 1. String formatting

| Canonical | Avoid |
|---|---|
| f-string: `f"{user}: {count}"` | `"%s: %d" % (user, count)` / `"{}: {}".format(user, count)` |
| `"\n".join(parts)` | manual concatenation with a trailing-separator loop |

- f-strings for interpolation; `%`/`.format` only where a stored template or logging's `%`-deferral genuinely requires it (`logger.info("x=%s", x)` is correct — don't f-string log args).

## 2. Iteration

| Canonical | Avoid |
|---|---|
| `for i, x in enumerate(seq):` | `for i in range(len(seq)): x = seq[i]` |
| `for a, b in zip(xs, ys):` | indexing two lists by a shared `range(len(...))` |
| comprehension / generator expression | `for`-loop that only `append`s to build a list |
| `for x in d:` / `d.items()` / `d.values()` | `for k in d.keys():` |

- Comprehension for a readable, side-effect-free build; a loop when there's mutation, early exit, or it doesn't fit one or two clauses.

## 3. Typing syntax

| Canonical | Avoid |
|---|---|
| `T | None` | `Optional[T]` |
| `X | Y` | `Union[X, Y]` |
| `list[str]`, `dict[str, int]`, `tuple[int, ...]` | `typing.List`, `typing.Dict`, `typing.Tuple` |

- Modern PEP 585/604 forms throughout. Pick one and don't mix `Optional[T]` and `T | None` in the same file.

## 4. None / identity / truthiness

- `x is None` / `x is not None`, never `x == None`.
- `is`/`is not` only for `None`, `True`/`False`, and unique sentinels — never for value equality of strings/ints (Ruff/`is`-literal lints).
- Be explicit when `0`/`""`/`[]` are valid values: `if x is None:` not `if not x:` when emptiness and absence differ.

## 5. Data structures & construction

| Canonical | Avoid |
|---|---|
| `@dataclass` / `NamedTuple` for fixed named fields | a dict/tuple passed around as an ad-hoc record |
| `enum.Enum` / `StrEnum` | module-level string/int constants for a closed set |
| `{k: v for ...}` / `dict(...)` | building an empty dict then `update` in a loop |
| `collections.defaultdict` / `Counter` | hand-rolled "if key not in d" accumulation |

## 6. Paths & files

- `pathlib.Path` over `os.path` string juggling: `path / name`, `path.read_text()`, `path.exists()`.
- `with open(...) as f:` always — never a bare `open` whose handle leaks.

## 7. Control flow

- `match`/`case` over a long `if/elif` chain when dispatching/destructuring on shape (PEP 634); a short `if/else` stays an `if/else`.
- Guard clauses / early return over nested `else`; keep the happy path at the lowest indentation. Avoid more than 2–3 levels of nesting.
- A conditional expression `a if cond else b` for a simple value choice; not a 4-line `if/else` assigning the same name twice.

## 8. Comprehension vs `map`/`filter`

- Comprehension/generator expression over `map`/`filter` with a `lambda`. Reach for `map`/`filter` only with an existing named function, and even then a comprehension usually reads better.

## 9. Imports

- Let Ruff/isort group and order imports (stdlib, third-party, first-party). Absolute imports over implicit relative; explicit relative (`from . import x`) only within a package.
- No wildcard imports (`from x import *`) outside a deliberate package `__init__` re-export.
- Don't alias on import unless there's a real collision or an established convention (`import numpy as np`).

## 10. Quotes, formatting & line length

- These belong to `ruff format`/Black — never hand-nit them. If a file isn't formatter-clean, the single finding is "run `ruff format`".

## Review wording

When you flag a consistency issue, say:
- which canonical form applies,
- that it is a strong default (not a hard rule), and the Ruff rule code if one exists,
- and whether the file mixes forms (mixing is the stronger finding).

Example: "Suggestion — this uses `Optional[str]` at line 30 where the file uses `str | None` elsewhere (line 52); `T | None` is canonical in `consistency.md` (PEP 604). Mixing the two is the noise. Strong default, not a hard rule."
