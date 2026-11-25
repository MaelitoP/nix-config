# Correctness & Concurrency Review Rules

The highest-priority lens. A correctness or safety bug outranks every style concern. TypeScript's types are erased and deliberately unsound in places, so the blocking concerns are the bugs that pass `tsc` and still break production: **unsoundness holes that reach runtime, nullish and truthiness confusion, swallowed or malformed errors, JavaScript runtime traps, and races on shared state**. Grounded in Dan Vanderkam's "The Seven Sources of Unsoundness", the TypeScript FAQ and tsconfig reference, the typescript-eslint `recommended-type-checked` / `strict-type-checked` rule docs, MDN, and the Node.js docs. (The promise and event-loop lens lives in `async.md`; the type-design lens in `types.md`.)

## 1. Unsoundness holes that reach runtime

### Hard rules

- `any` is infectious: one `any` disables checking on everything derived from it, and it arrives silently from `JSON.parse`, `Response.json()`, `Storage`, and loosely typed libraries. A value that came from one of those and is used as a domain type without narrowing or parsing is a finding. (`no-unsafe-assignment` / `-argument` / `-call` / `-member-access` / `-return`.)
- An assertion converts nothing. `x as T` and `x!` change what the checker believes, not what the value is; when the belief is wrong the failure surfaces far from the assertion.
  ```ts
  // Wrong: throws when property is absent
  example.property!.includes("baz");
  // Right
  example.property?.includes("baz") ?? false;
  ```
- Index access is typed `T`, not `T | undefined`, unless `noUncheckedIndexedAccess` is on. `xs[0]`, `record[key]`, a destructured array element, and `str.split(",")[1]` can all be `undefined`. Check the flag in `tsconfig.json`; without it, every unguarded lookup on data of unknown length is a potential finding.
- Object types are open, so `Object.keys(x)` is `string[]` and `for…in` yields `string`. Casting the key to `keyof T` is false certainty: the object can carry properties its type doesn't mention. (TypeScript FAQ.)

### Strong defaults

- Arrays are covariant: a function taking `Animal[]` can push a `Dog` into a caller's `Cat[]`. Parameters that aren't mutated are `readonly T[]`.
- Parameters of members written in method syntax are checked bivariantly; `strictFunctionTypes` applies only to function-typed properties. Declare callback members as properties: `onChange: (value: T) => void`, not `onChange(value: T): void`.
- Narrowing is not invalidated by a function call or an `await`. A property narrowed before a callback can be changed by it; copy it to a local `const` first.
- A wrong third-party `.d.ts` is fixed upstream or by augmentation, not papered over with an assertion at each use.
- Node's type stripping runs code without type-checking it. A repo that executes `.ts` directly must still run `tsc` in CI.

### Review questions

- Where does this value come from, and was it ever checked against the type it now has?
- If this lookup returned `undefined`, what would the next line do?

## 2. Nullish values & truthiness

### Hard rules

- `||` as a default discards valid `0`, `""`, `false`, and `NaN`. When those are legitimate values, it is a bug, not a style choice: use `??` / `??=`. (`prefer-nullish-coalescing`.)
  ```ts
  const limit = options.limit || 50;   // an explicit 0 becomes 50
  const limit = options.limit ?? 50;
  ```
- A truthiness check on a nullable primitive conflates absence with a valid zero or empty value: `if (count)` on `number | undefined`. Compare explicitly (`count !== undefined`). (`strict-boolean-expressions`.)
- An object reaching a template literal, `+`, `String()`, or `.join()` renders `[object Object]`. (`no-base-to-string`, `restrict-template-expressions`, `restrict-plus-operands`.)

### Strong defaults

- A condition the types say is always true or always false is dead code or a wrong type; find out which. (`no-unnecessary-condition`; TS 5.6 reports always-truthy and always-nullish checks as errors.)
- `===` everywhere; `== null` is the single accepted loose comparison.

### Review questions

- Are `0`, `""`, or `false` valid values on this path, and does the check treat them as missing?

## 3. Error-handling correctness

### Hard rules

- Throw and reject only `Error` objects; a thrown string or object literal has no stack and breaks every `instanceof` handler. (`only-throw-error`, `prefer-promise-reject-errors`.)
- A caught value is `unknown`. `catch (e)` is typed that way under `strict`, but a `.catch(err => …)` callback parameter is `any` regardless. Narrow before use. (`use-unknown-in-catch-callback-variable`.)
- No swallowed errors: an empty `catch`, `.catch(() => {})`, or a `catch` that logs and falls through to code that assumes success. An intentional ignore names the error it expects and says why.
- Preserve the cause when translating: `new DomainError("…", { cause: err })`. `cause` can be anything; don't assume it is an `Error`.
- A `return` (or `throw`) inside `finally` discards the pending exception or return value.
- A fallback value returned from a `catch` must be distinguishable from real data, or the caller cannot tell failure from success.

### Strong defaults

- Catch at the layer that can act. Don't log and rethrow at the same layer.
- `instanceof Error` is false for errors from another realm (iframe, worker, `vm`); at such a boundary check structurally. Use `AggregateError` for multiple failures.
- In Node, an unhandled rejection crashes the process by default, an `'error'` event with no listener throws, and it is not safe to resume after `'uncaughtException'`: clean up synchronously and exit. Code that installs a handler to keep running is a finding.

### Review questions

- Is an error caught and discarded on a path that can actually fail?
- After this `catch`, does the code continue as if the operation succeeded?

## 4. JavaScript runtime traps

### Hard rules

- `Array.prototype.sort()` with no comparator sorts by string: `[1, 30, 4, 100].sort()` is `[1, 100, 30, 4]`. It also sorts **in place**, mutating an array the caller may still hold. Use `toSorted((a, b) => a - b)`; a comparator returns a number, never a boolean. (`require-array-sort-compare`.) `reverse` and `splice` mutate too.
- `Date`: a date-only ISO string (`"2026-03-01"`) parses as UTC while a date-time without an offset parses as local time; non-ISO strings are implementation-defined; months are zero-indexed; setters mutate. Parse explicit ISO strings with an offset, never mutate a shared `Date`, and treat `Date` arithmetic across time zones or DST as suspect. `Temporal` reached Stage 4 in 2026 but is not yet available everywhere; use it behind a polyfill or feature check.
- A method detached from its object loses `this`: `const { save } = repo`, `items.map(repo.save)`, `setTimeout(obj.tick, 0)`. Wrap it (`x => repo.save(x)`). (`unbound-method`.)
- Never binary floating point for money or exact decimals (`0.1 + 0.2 !== 0.3`). Use integer minor units, `bigint`, or a decimal library; compare floats with a tolerance.
- `parseInt` accepts trailing garbage (`"15px"` → `15`, `"1e3"` → `1`) and its radix does not always default to 10. Pass the radix, or use `Number()` with an explicit `Number.isNaN` / `Number.isFinite` check when the whole string must be numeric.

### Strong defaults

- Object spread and `Array.from` copy one level. Mutating a nested value through a "copy" mutates the original; `structuredClone` deep-copies (and throws on functions and other non-cloneable values).
- Spreading a class instance drops its prototype and methods; spreading a `Map`, a promise, or a string into an object or array is almost always a mistake. (`no-misused-spread`.)
- No `for…in` over an array, no `delete` on array elements, no `delete` with a computed key on a typed object. (`no-for-in-array`, `no-array-delete`, `no-dynamic-delete`.)
- `JSON.stringify` drops `undefined` and functions, turns `NaN` into `null`, `Date` into a string, and throws on `bigint`; `Map` and `Set` serialize as `{}`. A round-trip through JSON does not return the same type.
- A closure created in a loop over `var`, or one that captures a variable later reassigned, sees the final value. `const` / `let` per iteration.

### Review questions

- Does this code mutate an array or object it received from a caller?
- Is a number compared, sorted, or parsed under an assumption the runtime does not share?

## 5. Shared state & races

JavaScript is single-threaded, not race-free: every `await` is a point where other code runs and shared state can change.

### Hard rules

- Check-then-act across an `await` is a race. The condition checked before the `await` may be false after it. (ESLint `require-atomic-updates`.)
  ```ts
  // Wrong: two concurrent callers both see no cache and both init
  if (!cache) cache = await init();
  // Wrong: lost update
  total += await fetchAmount();

  // Right: share the in-flight promise
  cache ??= init();
  const value = await cache;
  ```
- Module-level mutable state is shared by every request in a server and every test in a file. Per-request data stored in a module variable leaks between users.
- Out-of-order completion: when the same operation can be started twice, the earlier call can finish last and overwrite the newer result. Cancel the stale call (`AbortSignal`) or ignore its result.
- Data crossing to a worker is structured-cloned: prototypes and methods are lost, and non-cloneable values throw.

### Strong defaults

- Prefer immutable data and state confined to one owner; then there is nothing to race on.
- CPU-bound work blocks every other request (see `async.md`); it belongs on a worker pool, not behind an `await`.

### Review questions

- What else can run between this check and this write?
- Could two calls to this function interleave, and what would the second one see?

## 6. Interactions between changes in the same diff

Every lens above is single-site: it asks whether a line or a construct is wrong. Some defects exist at no single site — they are produced by two changes that are each correct alone. Nothing else in this document will find them.

This pass belongs to the serial whole-diff step in `SKILL.md`, which sees the complete diff. A single-lens agent should raise an interaction only when it can point at both changes and show the resulting output; otherwise it is speculation.

### Hard rules

- A diff fixing N defects has N(N-1)/2 possible interactions. Examine every pair that touches the same data path, even when each change is correct in isolation.
- Any change that **widens a set** — a union gaining a member, a property made optional, a schema relaxed, a type guard loosened, errors tolerated — must name the downstream branch that is now reached differently. A new union member without an exhaustiveness check lands in a `default`; a newly optional field meets a `!` or a truthiness check written for the old shape.
- A type change and a runtime change must agree. A widened type whose consumers were silenced with `as` / `!` compiles and is wrong.
- "It did not throw" is not "it produced the right value". A conversion — parsing, coercion, time zone, unit, serialization — can succeed and still be wrong. Judge the output, not the absence of an error.

### Review questions

- For every early `return` or `find` over ordered candidates: does another change in this diff alter which candidate now matches first?
- Is there a single input to which two of this diff's fixes both apply? If the tests never build one, the interaction is unverified.
- Does this diff replace a visible failure (a throw, a rejection, a rejected input) with a silent one (a fallback value returned successfully)? That trade is a regression even when the new path "works".

## 7. What makes a correctness finding blocking

Usually blocking:
- unparsed external data (`any` from `JSON.parse` / `.json()`) used as a typed value
- an `as` / `!` over a value that can be absent, or an unguarded index access on data of unknown length
- `||` or a truthiness check that mishandles a valid `0` / `""` / `false`, producing wrong results
- a swallowed error, a lost cause, a non-`Error` thrown, or a fallback indistinguishable from real data, on a path that can fail
- default `sort()` on numbers, or in-place mutation of a caller's array or object
- `Date` parsing or arithmetic that is wrong outside the author's time zone; float arithmetic for money
- a lost `this` on a detached method
- check-then-act across an `await`, per-request data in module state, or a stale response overwriting a newer one
- a fix that silently changes what a *different* fix in the same diff produces
- a blocked event loop or promise misuse (see `async.md`)

Usually suggestion:
- a missing `readonly` on an array parameter; a callback member in method syntax
- `noUncheckedIndexedAccess` off in a codebase with frequent index lookups
- a shallow copy that happens to be safe today
- a condition the types say is always true

Usually nit:
- error message wording
- a guard that could be expressed more directly
