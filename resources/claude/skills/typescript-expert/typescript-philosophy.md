# TypeScript Philosophy & Principles

The principles that ground every recommendation. Sources: *Effective TypeScript* (Dan Vanderkam) and effectivetypescript.com, Total TypeScript (Matt Pocock), Stefan Baumgartner's fettblog, Alexis King's "Parse, don't validate", the TypeScript handbook, FAQ, performance wiki and release notes, the Google TypeScript Style Guide, Kent C. Dodds, TkDodo, Jake Archibald, the typescript-eslint docs, and the Node.js docs. Cite these by name when advising.

## The overriding value: types are claims, and they are erased

- **TypeScript is JavaScript with a static claim attached.** Types vanish at compile time; nothing checks them at runtime. A type is true only because the compiler proved it or because someone promised it. Design so that the compiler proves as much as possible and the promises are few, local, and visible.
- **Every escape hatch is a promise.** `any`, `as`, `!`, `@ts-expect-error`, a hand-written type predicate, a return-only generic: each tells the checker to stop looking. They are not forbidden; they are debts. Give them the narrowest scope and put them where the proof is obvious. (*Effective TypeScript*: "Use the narrowest possible scope for `any` types", "Hide unsafe type assertions in well-typed functions".)
- **The checker is unsound on purpose, in known places.** Index access without `noUncheckedIndexedAccess`, array covariance, bivariant method parameters, narrowing that survives a function call, inaccurate declaration files, and assertions. Knowing the list is the difference between trusting a type and verifying it. (Vanderkam, "The Seven Sources of Unsoundness".)
- **Typing is structural.** A value is whatever shape it has; object types are open, so a value can carry more than its type mentions. That is why `Object.keys` returns `string[]`, why two same-shaped types are interchangeable, and why nominal distinctions need a brand.

## Make illegal states unrepresentable

- **Model the states, not the fields.** A discriminated union with a literal tag per variant, instead of one type with optionals and flags. If a value of the type can exist that the code does not handle, the type is wrong. (*Effective TypeScript*: "Prefer types that always represent valid states"; "Prefer unions of interfaces to interfaces with unions".)
- **Let the compiler enumerate for you.** An exhaustiveness check (`never`) turns "we added a case" from a runtime surprise into a compile error.
- **Precise where it pays, imprecise rather than wrong.** A literal union instead of `string`, a brand for an identifier, `readonly` for an input. But "prefer imprecise types to inaccurate types": a type that rejects valid values, or that nobody can read, is worse than a wide one.
- **Push absence to the perimeter.** Resolve `undefined` once at the edge and pass whole values inward, rather than making every signature optional.

## Parse at the boundary, trust inside

- **Parse, don't validate.** A check that returns nothing throws its knowledge away; a parser returns a more precise type that carries the proof. Data from outside the program is parsed once, where it enters, and the rest of the code receives the parsed type. (King.)
- **One source of truth.** Infer the static type from the schema (`z.infer`), derive related types from one definition (`typeof`, `keyof`, indexed access), and don't hand-copy shapes that must agree. Derive only between things that change together. (Baumgartner, "Low maintenance types"; Pocock.)
- **`unknown` is the type of the outside world.** `JSON.parse` and `Response.json()` say `any`; treat them as `unknown`.

## The simple type

- **Type-level code is code.** It has readers, bugs, and a compile-time cost, and its error messages are its user interface. "A little bit of repetition or verbosity is often much cheaper than the long term cost of complex type expressions." (Google style guide.)
- **A generic earns its place by relating two things.** The golden rule: a type parameter that appears once is noise; one that appears only in the return type is a hidden assertion. (Vanderkam; handbook.)
- **Unions before overloads before conditional types.** Reach for the next rung only when the previous one can't express the relationship.
- **Avoid hasty abstractions.** "Prefer duplication over the wrong abstraction", for types as for functions. (Dodds, "AHA Programming".)

## Prefer the platform: ECMAScript over TypeScript-only syntax

- **TypeScript's job is types.** The features it added to the runtime — `enum`, runtime `namespace`, parameter properties, `import =` — are the ones the ecosystem is leaving behind. `erasableSyntaxOnly` (TS 5.8) rejects them, and Node's built-in type stripping cannot run them. Write code that is valid JavaScript once the types are deleted. (*Effective TypeScript*: "Prefer ECMAScript features to TypeScript features".)
- **Use what the platform already has** before a utility or a dependency: `structuredClone`, `Object.groupBy`, `Array.prototype.at` / `toSorted` / `with`, `Map` / `Set`, `URL`, `Intl`, `AbortSignal.timeout` / `any`, `Promise.withResolvers` / `try`, `using` for disposal, `Error` `cause`. `Temporal` reached Stage 4 in 2026 and is the direction for dates; check availability before relying on it.
- **ES modules, named exports, direct imports.** No default exports, no barrels in application code, no cycles. (Google; TkDodo; Marvin Hagemeister on barrel-file cost.)

## Async is a design constraint, not a keyword

- **A promise must have an owner.** Awaited, returned, or explicitly handled; a floating promise is a lost error and an unbounded lifetime. (`no-floating-promises`.)
- **Every `await` is a yield point.** Single-threaded does not mean race-free: state checked before an `await` may be stale after it.
- **Promises are eager and uncancellable.** Starting one commits to it; a combinator does not stop the losers. Cancellation is an `AbortSignal` you thread through deliberately, and every outbound call needs a deadline.
- **One thread serves everyone.** A slow synchronous callback delays every other request. Bound input sizes; move CPU work to workers. (Node, "Don't Block the Event Loop"; Archibald on unhandled rejections and `return await`.)

## Errors

- **A caught value is `unknown`,** and TypeScript cannot declare what a function throws. So failures a caller is expected to handle are more honestly a returned union; defects throw. Either way: only `Error` instances, always with `cause`, and a literal discriminant when callers must tell kinds apart. This is a contested area — hold the default, respect the codebase's convention, and never mix both styles for the same kind of failure.

## Tooling is part of the language

- **The compiler configuration is part of the code's meaning.** `strict` is the floor (and the default since TypeScript 6.0). The consensus additions: `noUncheckedIndexedAccess`, `noImplicitOverride`, `verbatimModuleSyntax`, `isolatedModules`, `moduleDetection: force`. Stricter still, and a judgment call per codebase: `exactOptionalPropertyTypes`, `noPropertyAccessFromIndexSignature`. (Pocock's TSConfig cheat sheet; `@tsconfig/strictest`.)
- **Module settings follow the runtime.** Bundled app: `module: preserve` + `moduleResolution: bundler` + `noEmit`. Node app or any library: `module: nodenext`, with file extensions in relative imports; `bundler` resolution in a library produces output Node cannot load. (Handbook, "Choosing Compiler Options"; Andrew Branch.)
- **Know which compiler you are on.** TypeScript 7.0 (July 2026) is the native Go compiler, roughly ten times faster, with the 6.0 deprecations now hard errors: no `baseUrl`, no `moduleResolution: node`, no `target: es5`, no AMD/UMD/System output. It ships without the old programmatic API, so tools that import `typescript` (and Vue/Svelte/Angular template checking) may still need 6.x alongside. Check before recommending a toolchain change.
- **Type-aware linting is the baseline, not an extra.** The rules that matter most need type information: `no-floating-promises`, `no-misused-promises`, the `no-unsafe-*` family, `switch-exhaustiveness-check`, `no-unnecessary-condition`. typescript-eslint's `recommended-type-checked` and `strict-type-checked` presets provide them on TypeScript 6.x; on TypeScript 7, `oxlint --type-aware` is the stable type-aware option. Biome's type-aware rules are still mostly in its nursery group.
- **The formatter ends formatting debates.** Prettier or Biome; never hand-fight it.
- **Type stripping is not type checking.** Node runs `.ts` files by deleting the types; `tsc --noEmit` in CI is what checks them.
- **Tests prove behavior.** Vitest by default; test through what a consumer observes, mock only at seams you own, control time with fake timers rather than sleeps, and test exported generic types with `expectTypeOf`. (Dodds; see `../typescript-review/testing.md`.)

## Precedents to cite

These usually end a debate — point at the canon:

- State modelling: discriminated unions and `never` exhaustiveness (handbook, Narrowing); "prefer types that always represent valid states" (*Effective TypeScript*).
- Generics: the golden rule (Vanderkam; handbook "type parameters should appear twice"); `NoInfer` (5.4); `const` type parameters (5.0).
- Assertions and inference: `satisfies` (4.9) with `as const`; inferred type predicates (5.5); "The Seven Sources of Unsoundness".
- Boundaries: "Parse, don't validate" (King); schema inference (`z.infer`); Standard Schema.
- Erasable syntax: `erasableSyntaxOnly` (5.8), `verbatimModuleSyntax`, Node type stripping; "prefer ECMAScript features to TypeScript features".
- Async: `no-floating-promises`, `no-misused-promises`, `return-await`; Archibald on unhandled rejections; `AbortSignal.timeout` / `AbortSignal.any`; `using` (5.2).
- Modules: Google style guide on named exports; TkDodo and Hagemeister on barrel files; the handbook's "Choosing Compiler Options".
- Design restraint: Dodds's "AHA Programming", "Colocation", "Inversion of Control"; Google on the cost of complex type expressions.
- Handbook "Do's and Don'ts": no `Number`/`String`/`Object`, no `any` outside migration, unions before overloads, callbacks return `void`.
