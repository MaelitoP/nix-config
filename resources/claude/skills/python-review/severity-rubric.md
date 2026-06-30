# Severity Rubric (Python)

Use this rubric to classify findings consistently. Python is dynamically typed with no compile-time race or null safety, so blocking findings concentrate on what slips past the interpreter until runtime: mutable-default bugs, identity/truthiness confusion, swallowed exceptions, resource leaks, broken equality/hash contracts, numeric traps, races, and blocked event loops.

## Blocking

Use `Blocking` when the issue should realistically stop the PR from merging.

Typical blocking cases:
- a mutable default argument accumulating state across calls
- `== None` / `is`-on-values / a truthiness check that mishandles a valid `0`/`""`/empty value — producing wrong results
- a late-binding closure capturing the loop variable
- a swallowed exception (bare `except`, `except Exception: pass`), a lost cause, or `return` in `finally`, on a path that can fail
- a resource leak: a file/socket/lock/session/`subprocess` not acquired with `with`
- `__eq__` defined without a consistent `__hash__` (or a mutable object used as a hash key)
- `float` for money, or a float `==` comparison, yielding wrong results
- a data race: unsynchronized shared mutable state across threads, or a compound action (`+=`, check-then-act) assumed atomic
- a blocked event loop (blocking call in a coroutine), a swallowed `CancelledError`, a fire-and-forget `create_task` GC leak, or an un-awaited coroutine (see `async.md`)
- a mypy error or a Ruff error-class finding (`F`/`E9`/`B`) that's a real bug, or an unformatted file
- a missing regression test for a bug fix, or a behavioral change on a critical path with no meaningful coverage

Ask:
- Could this produce wrong results, leak, race, deadlock, or stall the loop in production?
- Does it break an equality/hash contract or a documented project rule?
- Does it violate a tool gate the build enforces (mypy error, Ruff error, failing `ruff format --check`)?

## Suggestion

Use `Suggestion` for important improvements that should be fixed but don't block on their own.

Typical suggestion cases:
- non-idiomatic construct where idiomatic Python is clearly better (`range(len(...))` indexing → `enumerate`/`zip`; manual accumulation → comprehension/generator; LBYL pre-check → EAFP; `os.path` → `pathlib`; getters/setters → `@property`; string constants → `Enum`; loose dict → `@dataclass`)
- typing gaps: a public signature missing types, a bare `Any` leaking across a boundary, `Optional[T]`/`typing.List` instead of `T | None`/`list[str]`, a `str` where a `Literal`/`Enum` belongs
- broad `except Exception` where a specific type fits; a missing `raise ... from`
- single-syntax / consistency deviation from `consistency.md` (especially a file mixing two forms), or an unaddressed Ruff warning
- CPU-bound work on threads where processes are warranted; `gather` where a `TaskGroup` is safer
- weak naming that isn't actively misleading; a `utils`/`helpers` junk-drawer module; a mutable attribute that should be `frozen`/immutable; missing docstrings on public API
- a class that should be a function; a loose dict/tuple that should be a dataclass/NamedTuple
- missing edge-case/exception-path test on a non-critical path; copy-paste tests that should be parameterized; mocking a value type

Ask:
- Does this make the code meaningfully harder to read, evolve, or use correctly?
- Is it a strong idiom/consistency default rather than a hard rule?

## Nit

Use `Nit` for low-impact polish.

Typical nit cases:
- exception/`match` message wording
- assertion phrasing, test naming
- a small rename, a simplifiable expression, a conditional expression where a 4-line `if/else` was used
- docstring phrasing
- a `with`/lock scope that could tighten for readability

Never raise a formatter-owned formatting issue as a per-line nit — the single finding is "run `ruff format`". Never restate a Ruff/mypy finding line-by-line — cite the rule/error code once.

## Confidence

Every finding includes confidence:
- `high`: clear violation, bug, or contract break
- `medium`: likely issue, but local context may justify it
- `low`: speculative; raise carefully and explain the uncertainty

## Preference vs rule

Say explicitly when something is a preference or strong default rather than a hard rule.

Good: "Suggestion — not a hard rule, but this fights the comprehension default in `consistency.md`, and Ruff flags the adjacent case."

Bad: presenting an idiom or consistency preference as if it were a correctness bug.
