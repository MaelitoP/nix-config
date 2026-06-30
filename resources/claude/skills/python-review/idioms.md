# Idioms, API Design & Naming Review Rules

Grounded in *Effective Python* (Brett Slatkin), *Fluent Python* (Luciano Ramalho), the Zen of Python (PEP 20), PEP 8, PEP 257, the typing PEPs, Raymond Hettinger's idiom talks, and the Ruff idiom lints. These are how idiomatic Python reads. Deviation needs a reason.

## 1. Naming

### Hard rules

- Casing (PEP 8): `snake_case` for functions, methods, variables, and modules; `CapWords`/`PascalCase` for classes, exceptions, and type variables; `UPPER_SNAKE_CASE` for module-level constants; `_leading_underscore` for non-public members; `__dunder__` only for the data model.
- Packages and modules are short, all-lowercase names (no underscores where avoidable).
- Don't prefix interfaces/protocols with `I` or suffix the only implementation with `Impl`.

### Common weak names to flag

- `Manager`, `Helper`, `Util`/`Utils`, `Processor`, `Handler` (when not an actual handler), `data`, `info`, `obj`, `tmp`, `Base`, `common`, `misc`, single-letter names outside tight scopes.
- A `utils.py`/`helpers.py`/`common.py` module full of unrelated functions is almost always a cohesion failure — put each function on the type or in the module it belongs to.

### Review questions

- Would a reader predict this function's behavior from its name?
- Does the name describe the domain, or the mechanism?

## 2. EAFP over LBYL

### Strong defaults

- Prefer "ask forgiveness" (try/except) to "look before you leap" (pre-checking) — LBYL races and reads worse (Python glossary; Hettinger).
  ```python
  try:
      return cache[key]
  except KeyError:
      return compute(key)
  ```
- Catch the **narrowest** exception, around the **smallest** scope that can raise it. Never a bare `except:` (catches `SystemExit`/`KeyboardInterrupt`) — and `except Exception` only at a deliberate boundary.

### Review questions

- Is there an `if key in d: ... else: ...` (or `hasattr`/`os.path.exists` pre-check) where try/except is cleaner and race-free?

## 3. Iteration & comprehensions

### Strong defaults

- Iterate with `enumerate`, `zip`, and tuple unpacking — not `range(len(seq))` and manual indexing (Hettinger; *Effective Python*). "When you're manipulating indices, you're probably doing it wrong."
- Use a comprehension for a clear, side-effect-free build of a list/dict/set. Keep it readable: at most one or two `for`/`if` clauses; a deeply nested comprehension should be a loop (*Effective Python*).
- Prefer a **generator** (`yield` or a generator expression) when the caller iterates once or the sequence is large — don't build a list to throw it away.
- Don't put side effects in a comprehension; a comprehension whose point is the `for` body's effect should be a loop.

## 4. Exceptions

### Hard rules

- Never use a bare `except:`; never swallow an exception silently ("errors should never pass silently", Zen). If you genuinely mean to ignore one, use `contextlib.suppress(SpecificError)` or `except SpecificError: pass` with a one-line reason.
- Chain causes: `raise DomainError(...) from err` (or `from None` to deliberately drop the chain) — losing the cause erases the traceback.
- Use exceptions for exceptional conditions, not control flow. Raise a *specific* type subclassing a sensible built-in; favor the standard exceptions (`ValueError`, `KeyError`, `TypeError`, `LookupError`, `RuntimeError`) where they fit.

### Strong defaults

- Validate inputs and fail fast with a clear `ValueError`/`TypeError`; include the offending value in the message.
- Don't both log and re-raise the same exception at one layer (double reporting).

## 5. Dataclasses, enums, Protocols & ABCs

### Strong defaults

- Model structured data as a `@dataclass` (add `frozen=True` for value objects) rather than a loose dict or a tuple of positional fields — you get `__init__`, `__repr__`, `__eq__` for free (PEP 557). A `NamedTuple` when it should also behave like a tuple; a `TypedDict` to type a dict shape at a boundary (no runtime checks); **pydantic** to validate untrusted input.
- Use an `enum.Enum`/`StrEnum` instead of string/int constants (typed, exhaustively matchable, prints meaningfully).
- For an interface a type checker should verify, prefer a `typing.Protocol` (structural, no inheritance needed — PEP 544); use an `abc.ABC` when you need runtime enforcement or shared mixin implementation. Type parameters against `collections.abc` (`Iterable`, `Mapping`, `Sequence`), not concrete `list`/`dict`.
- Prefer `match`/`case` over a long `if/elif` chain when destructuring or dispatching on shape (PEP 634).

### Review questions

- Is this a dict/tuple of fixed, named fields that should be a dataclass/NamedTuple?
- Is an ABC used where a `Protocol` (no inheritance) would be more flexible — or a `Protocol` where runtime enforcement is actually required?

## 6. Context managers & resources

### Hard rules

- Every resource (file, socket, lock, DB session, `subprocess`, `tempfile`) is acquired with `with` so it's released on every path, including exceptions. A hand-written try/finally that re-implements a context manager is a finding.
- Write your own with `contextlib.contextmanager` or `__enter__`/`__exit__` when you own a resource lifecycle.

## 7. Properties & object design

### Strong defaults

- Expose data as attributes; add a `@property` only when you need computed access or validation — don't write Java-style `get_x`/`set_x` (*Effective Python*).
- Prefer a function to a class whose only methods are `__init__` and one other ("stop writing classes"). Reach for a class when there's genuine state with invariants and several cohesive methods.
- Favor composition over inheritance; keep inheritance shallow.

## 8. Typing precision

### Hard rules

- Annotate public function signatures and module boundaries (PEP 484). A public function missing a return type, or leaking a bare `Any`, is a finding.
- Use modern syntax: `T | None` over `Optional[T]` (PEP 604); `list[str]`/`dict[str, int]` over `typing.List`/`Dict` (PEP 585).

### Strong defaults

- Tighten values with `Literal[...]`, `Enum`, and `NewType` where a plain `str`/`int` would admit wrong values.
- Type collaborators by capability (`Iterable[T]`, `Mapping[K, V]`, a `Protocol`), not by concrete class.
- Narrow `Any` as soon as it enters; an `Any` that flows through the public API defeats the checker.

### Review questions

- Does a public signature lack types, or admit a value it shouldn't (a bare `str` where a `Literal`/`Enum` fits)?
- Does `Any` leak across a module boundary?

## 9. Documentation

### Hard rules

- Public modules, classes, and functions carry docstrings (PEP 257): a one-line summary for the obvious case; a structured docstring (summary, args, returns, raises) for non-trivial public functions.

### Review questions

- Does a public function/class have a docstring stating what it does and what it raises?
