# Idioms, API Design & Naming Review Rules

Grounded in the Google TypeScript Style Guide, the TypeScript handbook ("Do's and Don'ts"), *Effective TypeScript* (Dan Vanderkam), Total TypeScript (Matt Pocock), Kent C. Dodds ("Colocation", "AHA Programming", "Inversion of Control"), TkDodo's blog, and the typescript-eslint rule docs. These are how idiomatic TypeScript reads. Deviation needs a reason. (Type-system rules live in `types.md`; the canonical spelling of each construct lives in `consistency.md`.)

## 1. Naming

### Hard rules

- Casing: `lowerCamelCase` for variables, parameters, functions, methods, and properties; `UpperCamelCase` for classes, interfaces, type aliases, and type parameters; `CONSTANT_CASE` for module-level constants that are genuinely constant. (Google; TS team guidelines.)
- No `I` prefix on interfaces, no `T` prefix on type aliases, no `_` prefix or suffix for private members, no type information encoded in a name (`userArray`, `nameString`).
- Treat acronyms as words: `loadHttpUrl`, `userId`, not `loadHTTPURL`, `userID`.

### Strong defaults

- Name types in the language of the domain, not of the mechanism (*Effective TypeScript*). Booleans read as predicates (`isActive`, `hasAccess`, `canRetry`).
- A type parameter is a single capital (`T`, `K`) when its role is obvious, or a descriptive `UpperCamelCase` name (`TItem`) when there are several. Pick one style per file.
- One file-name convention per repository, lint-enforced. Which one is house style; mixing is the finding.

### Common weak names to flag

- `Manager`, `Helper`, `Util`/`Utils`, `Processor`, `Handler` (when not an actual handler), `Service` as a default suffix, `data`, `info`, `obj`, `item`, `tmp`, `Base`, `common`, `misc`, single letters outside a scope of a few lines.
- `utils.ts` / `helpers.ts` / `common.ts` full of unrelated functions, and a global `types.ts` dumping ground: cohesion failures. Put each function and type next to the code that owns it (Dodds, "Colocation").

### Review questions

- Would a reader predict this function's behavior from its name at the call site?
- Does the name describe the domain, or the mechanism?

## 2. Functions & signatures

### Strong defaults

- No boolean flag parameters. `render(true, false)` is unreadable at the call site, and a flag that switches behavior is two functions. Take an options object, a literal union, or split the function.
- More than two or three positional parameters, or two of the same type in a row, become an options object.
- Inputs the function does not mutate are `readonly` (see `types.md`). Don't mutate arguments; return a new value.
- Prefer inversion of control to a growing list of options: accept a callback or a collaborator rather than another flag (Dodds).
- Callbacks: return `void` when the result is ignored; don't declare optional callback parameters; don't write overloads that differ only in callback arity (handbook).
- Exported functions carry an explicit return type (see `types.md`).

### Review questions

- Is there a boolean argument whose meaning is invisible at the call site?
- Does this function mutate what it was given?

## 3. Errors

### Hard rules

- Throw only `Error` instances (or subclasses), and reject promises only with them: a thrown string has no stack. (`only-throw-error`, `prefer-promise-reject-errors`.)
- Preserve the cause when translating: `throw new OrderError("payment failed", { cause: err })`.
- No empty `catch`. Catch only what you can handle, at the layer that can handle it; an intentional ignore carries a one-line reason.
- Treat the caught value as `unknown` and narrow before reading `.message`.

### Strong defaults

- Expected, domain-level failures the caller must handle (not found, validation failed, insufficient funds) belong in the return type as a discriminated union; defects and broken invariants throw. This is contested across the ecosystem, so match the codebase: the finding is a *mix* of both styles for the same kind of failure, or an expected failure the signature hides.
  ```ts
  type ParseResult =
    | { ok: true; value: Config }
    | { ok: false; error: ConfigError };
  ```
- Distinguish error kinds with a literal discriminant (`code`, `kind`) on the error type rather than `instanceof` alone: structurally identical classes unify, and a discriminant gives exhaustive handling.
- Custom errors extend `Error`, set `name`, and carry structured fields rather than a message to be parsed.
- Don't log and rethrow the same error at one layer.

### Review questions

- Is a failure the caller must handle invisible in the signature?
- Is the original error dropped when a new one is thrown?

## 4. Classes, functions & dependencies

### Strong defaults

- Prefer a function, or a module of functions, to a class. A class with one public method and no state is a function with ceremony; a static-only class is a module. Reach for a class when there is state with invariants and several cohesive methods over it.
- Type against structure, not against a class: declare what a collaborator must do as a small interface on the consumer's side, and accept that (Google: "use interfaces to define structural types, not classes").
- Pass collaborators as arguments (constructor or function parameters, or a factory closing over them). No module-level singletons reached for from inside logic, no import-time side effects. A DI container or new decorators need a reason the plain form lacks.
- Class hygiene: `readonly` on every field not reassigned after construction; `override` on overrides (`noImplicitOverride`); no `public` keyword noise; getters are pure; module-local functions instead of private static methods; no mixins or prototype patching.
- Composition over inheritance; keep hierarchies shallow. `implements` states a contract, `abstract` shares implementation.
- A method passed as a callback loses `this`. Pass an arrow (`() => svc.run()`) or define the member as an arrow property.

### Review questions

- Would this class be clearer as one or two functions?
- Does this module reach for a global it should have been handed?

## 5. Modules & exports

### Hard rules

- Export only what is used outside the module; no `export let`. Every exported symbol is API someone will depend on.
- No circular imports. (`import/no-cycle`.)
- Type-only imports are marked as such (see `consistency.md`), so they are erased and cannot create runtime cycles.

### Strong defaults

- Named exports, not default exports: a default export has no canonical name, so it is renamed inconsistently and refactors worse (Google).
- No barrel files (`index.ts` re-exports) in application code: they create import cycles and force every re-exported module to load. A library's package entry point is the one place a barrel belongs (TkDodo, "Please Stop Using Barrel Files").
- Colocate: types, tests, and helpers live beside the code that owns them. Extract shared code when a second real use appears, not before; "prefer duplication over the wrong abstraction" (Dodds, "AHA Programming").
- Don't leak third-party, ORM, or transport types across a module boundary; map to a domain type at the edge.
- Prefer ECMAScript features to TypeScript-only runtime syntax (*Effective TypeScript*): enums, runtime namespaces, and parameter properties are rejected by `erasableSyntaxOnly` and by Node's type stripping.

### Review questions

- Is anything exported that only this file uses?
- Does this import pull a whole directory through a barrel for one symbol?

## 6. Immutability & data

### Strong defaults

- `const` by default; `let` only when reassigned; never `var`.
- Don't mutate shared data. Use the copying array methods (`toSorted`, `toReversed`, `toSpliced`, `with`) and spread; note that spread and `Readonly` are shallow.
- A `Map` / `Set` for dynamic keys and membership, a plain object for a fixed, known shape. An index-signature object used as a hash map invites prototype-key and `undefined`-access bugs.
- A constant table is an `as const` object or array, with the union derived from it (TkDodo, "The power of const assertions").
- A named object over a tuple once there are more than two elements or the positions aren't obvious.

## 7. Control flow & readability

### Strong defaults

- Guard clauses and early returns; keep the happy path at the lowest indentation.
- `async`/`await` over `.then` chains (see `async.md`).
- No nested ternaries. A `switch` over a union tag with an exhaustiveness check over an `if` ladder (see `types.md`).
- Platform before dependency before hand-rolled: `structuredClone`, `Object.groupBy`, `Array.prototype.at`, `URL`, `Intl`, `AbortSignal.timeout` before a utility function or a package.

## 8. Documentation

### Hard rules

- TSDoc (`/** … */`) on exported API states behavior, units, and failure modes. Never restate types in the comment: `@param {string} name` is redundant and drifts (Google; *Effective TypeScript*).
- `@deprecated` says what to use instead.

### Strong defaults

- `//` comments explain why, never what. A comment narrating the code is noise.

### Review questions

- Does an exported function say what it throws or rejects with, when that isn't obvious from the types?
