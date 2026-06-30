# Python Philosophy & Principles

The principles that ground every recommendation. Sources: the Zen of Python (PEP 20, Tim Peters), PEP 8 (van Rossum, Warsaw, Coghlan), PEP 257 (docstrings), *Effective Python* (Brett Slatkin), *Fluent Python* (Luciano Ramalho), Raymond Hettinger's *Transforming Code into Beautiful, Idiomatic Python*, the typing PEPs (484, 526, 585, 604, 544, 589, 634), and David Beazley's concurrency talks. Cite these by name when advising.

## The overriding value: readability and "one obvious way"

- **Readability counts.** (Zen of Python.) Code is read far more than it's written; optimize for the next reader. Python's whitespace, small keyword set, and PEP 8 exist so that all Python reads the same way.
- **Explicit is better than implicit.** Prefer the spelling that states intent. Magic, clever metaprogramming, and hidden side effects cost the reader.
- **Simple is better than complex; flat is better than nested.** Guard clauses and early returns keep the happy path at the left margin; deep nesting hides logic. Reach for the obvious solution first.
- **There should be one — and preferably only one — obvious way to do it.** This is the basis for the single-syntax consistency rules: when the language offers two spellings for the same thing, pick the canonical one and stay with it. Uniformity beats novelty.
- **Errors should never pass silently — unless explicitly silenced.** A bare `except:` or a swallowed exception is a Zen violation, not a style nit.

## EAFP: ask forgiveness, not permission

- **Prefer EAFP to LBYL.** "It's easier to ask forgiveness than permission" — try the operation and catch the exception, rather than pre-checking with `if`. LBYL ("look before you leap") races (the state can change between the check and the use) and reads worse. (Python glossary; Hettinger.)
  ```python
  try:
      return cache[key]
  except KeyError:
      return compute(key)
  ```
- **Catch the narrowest exception that can occur**, and only around the line that raises it. A broad `except Exception` around a whole block hides bugs.
- **Chain causes.** When translating an exception, `raise DomainError(...) from err` so the original traceback survives.

## Duck typing and the data model

- **If it walks like a duck…** Python dispatches on behavior, not declared type. Code against what an object *can do* (`Iterable`, `Mapping`, a `Protocol`) rather than what it *is*. (Ramalho, *Fluent Python*.)
- **The data model is the API.** Implement the dunder methods (`__len__`, `__iter__`, `__getitem__`, `__eq__`, `__hash__`, `__repr__`, `__enter__`/`__exit__`) and your objects work with the language's built-in functions, operators, and `for`/`with` constructs. Don't reinvent what a dunder gives you. (*Fluent Python* ch. 1.)
- **Functions are first-class objects.** Pass them, return them, store them. A closure or a higher-order function often beats a class with a single method. (*Fluent Python*; "stop writing classes".)
- **Idioms over index manipulation.** Iterate with `enumerate`, `zip`, and tuple unpacking, not `range(len(...))` and manual indexing. (Hettinger; *Effective Python*.)

## Explicit, gradual typing pushes correctness into the checker

- **Type hints are part of modern Python.** Annotate public signatures and module boundaries so mypy/pyright catch mismatches the runtime won't (PEP 484). Gradual typing means you can leave a private helper loose, but the surface other code calls should be typed.
- **Use the modern forms.** `T | None` over `Optional[T]` (PEP 604); `list[str]`/`dict[str, int]` over `typing.List`/`Dict` (PEP 585); `Protocol` for structural interfaces (PEP 544). Avoid bare `Any` — it switches type-checking off.
- **Precise types make illegal states harder to build.** An `Enum` instead of string constants, a `Literal[...]` for a fixed set, a `@dataclass` instead of a loosely-typed dict, a `NewType` for an id — each lets the checker reject a wrong value.

## Prefer immutability; confine shared state

- **Immutable is simpler and thread-safe.** `@dataclass(frozen=True)` value objects can be shared freely, hashed, and reasoned about without locks. Produce changes with `dataclasses.replace`.
- **Confine mutable state.** The easiest concurrency bug to avoid is the one in state you never share. Keep mutable state owned by one thread/task; share only immutable data or coordinate through a queue.
- **Know the GIL.** CPython's global interpreter lock serializes Python bytecode, so threads don't speed up CPU-bound work (use processes) but do help I/O-bound work (the lock is released during I/O). Asyncio gives high I/O concurrency on one thread. (Beazley.) The free-threaded build (PEP 703) is experimental.

## Batteries included — don't reinvent the stdlib

- **Reach for the standard library first.** `pathlib` for paths, `dataclasses` for records, `enum` for constants, `itertools`/`functools` for iteration and composition, `collections` (`defaultdict`, `Counter`, `deque`) for common structures, `contextlib` for context managers, `concurrent.futures` for pools. (*Effective Python*: "know your standard library".)
- **A little stdlib beats a dependency.** Every third-party package is a liability; prefer the built-in where it's adequate.
- **Docstrings document the public surface.** PEP 257: a one-line docstring for the obvious case, a structured multi-line docstring (summary, args, returns, raises) for public functions/classes/modules.

## Tooling is part of the language

- **The formatter ends formatting debates.** `ruff format` (or Black) makes all Python in a repo read the same way — never hand-fight it; uniformity beats preference.
- **Listen to the linter and the type checker.** Ruff (linting; it subsumes flake8/isort/pyupgrade/pydocstyle) and mypy/pyright (typing) are the Python analog of `cargo clippy`/`go vet`. A warning is a finding, not noise.
- **Write tests with pytest.** Plain `assert` (pytest rewrites it into rich failures), fixtures for setup, `parametrize` over copy-paste, fakes/mocks only at seams you own. (See `../python-review/testing.md`.)

## Precedents to cite

These usually end a debate — point at the canon:

- Iteration idioms: `enumerate`, `zip`, `itertools.chain`/`islice`/`groupby`, generator expressions.
- Records & constants: `dataclasses.dataclass`, `typing.NamedTuple`, `enum.Enum`/`StrEnum`/`auto`.
- Paths & files: `pathlib.Path` over `os.path`; `open(...)` as a context manager.
- Context managers: `contextlib.contextmanager`, `contextlib.suppress`, `with` for every resource.
- Structural interfaces: `collections.abc` (`Iterable`, `Mapping`, `Sequence`, `Hashable`), `typing.Protocol`.
- Composition & functional tools: `functools.partial`, `functools.cached_property`, `functools.total_ordering`, `functools.lru_cache`.
- Concurrency: `concurrent.futures.ThreadPoolExecutor`/`ProcessPoolExecutor`, `asyncio.TaskGroup`, `asyncio.to_thread`, `queue.Queue`.
- Typed absence and shapes: `T | None`, `typing.Literal`, `typing.TypedDict`, `typing.NewType`.
