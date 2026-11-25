# Single-Syntax Consistency Rules

This is the "one way to do things" doc. A formatter (Prettier / Biome) removes layout debates; this file extends that uniformity to the choices the formatter leaves open. When the same thing can be written two ways, **pick the canonical form below** and flag deviations. The goal is to remove noise so readers spend attention on logic, not on incidental variety.

These are **opinionated strong defaults**, not hard language rules. Flag a deviation as a `Suggestion` and name the canonical form. Allow a deviation only when there is a concrete local reason, and say so. Many of these are typescript-eslint rules — when the linter already flags it, cite the rule name instead of restating it.

**The repository's lint config outranks this file.** Where experts genuinely disagree (marked *contested* below), the project's configured rule is canonical; this file is the default only when the project is silent. In every case the strongest finding is a file that mixes both forms.

## How to apply

For each rule: the canonical form is on the left, the discouraged variant on the right. A diff that introduces the discouraged form — or a file that uses both forms for the same purpose — is a finding.

## 1. Declarations & equality

| Canonical | Avoid |
|---|---|
| `const`; `let` only when reassigned | `var` |
| `===` / `!==` | `==` / `!=` (sole exception: `x == null` to cover both nullish values) |
| `x as T` | `<T>x` |
| `string`, `number`, `boolean`, `object` | `String`, `Number`, `Boolean`, `Object` |

## 2. Nullish handling

| Canonical | Avoid |
|---|---|
| `a ?? b` | `a \|\| b` as a default (wrong for valid `0` / `""` / `false`) |
| `a?.b?.c` | `a && a.b && a.b.c` |
| `x ??= init()` | `if (x === undefined) x = init()` |

- One absence value per codebase. Default to `undefined` in your own code (it is what optional properties, missing arguments, and `Map.get` already produce) and keep `null` where a boundary produces it (JSON, DOM, SQL). *Contested*; the finding is a module that uses both for the same meaning.
- `prefer-nullish-coalescing`, `prefer-optional-chain`.

## 3. Object types: `interface` vs `type`

| Canonical | Avoid |
|---|---|
| `interface User { … }` for an object shape | `type User = { … }` for the same |
| `type` for unions, tuples, function types, mapped and conditional types | an `interface` contorted to do those |
| `interface B extends A` | `type B = A & { … }` |

- *Contested.* The handbook, the Google style guide, and typescript-eslint's `consistent-type-definitions` default say `interface` for object shapes; Matt Pocock recommends `type` by default (no accidental declaration merging, implicit index signature). Follow the project's lint rule. What everyone agrees on: be consistent, and use `interface extends` rather than `&` to extend an object type (the compiler caches interfaces and reports property conflicts).

## 4. Closed sets of values

| Canonical | Avoid |
|---|---|
| `type Status = "draft" \| "live"` | `enum Status { … }` in new code |
| `const Status = { Draft: "draft", Live: "live" } as const` + a derived type, when the values are needed at runtime | `const enum`; numeric enums |

```ts
const Status = { Draft: "draft", Live: "live" } as const;
type Status = (typeof Status)[keyof typeof Status];
```

- Enums emit runtime code, string enums are nominal unlike everything else in the language, and `erasableSyntaxOnly` / Node type stripping reject them. Don't rewrite an existing enum for its own sake; don't add a new one, and don't mix enums and unions for the same concept.

## 5. Array & index types

| Canonical | Avoid |
|---|---|
| `T[]`, `readonly T[]` | `Array<T>`, `ReadonlyArray<T>` for a simple element type |
| `Record<K, V>` for a fixed key set; `Map<K, V>` for dynamic keys | `{ [key: string]: V }` used as a hash map |

- `Array<T>` is acceptable when the element type is itself complex (`Array<{ id: string } | null>`). `array-type`.

## 6. Imports & exports

| Canonical | Avoid |
|---|---|
| `import type { User } from "./user"` | `import { User }` for a type-only use |
| named exports | `export default` |
| direct import from the defining module | import through a barrel `index.ts` |
| ES modules | `namespace`, `import x = require()`, `export =` |

- Under `verbatimModuleSyntax`, `import { type User }` still emits an empty runtime import; a top-level `import type` is erased entirely. `consistent-type-imports`.

## 7. Functions

| Canonical | Avoid |
|---|---|
| `function name() {}` for named, module-level functions | `const name = function () {}` |
| arrow functions for callbacks and inline closures | `function` expressions as callbacks |
| options object / literal union | positional boolean flags |

- Don't mix `function` declarations and `const` arrows for module-level functions in the same file.

## 8. Async

| Canonical | Avoid |
|---|---|
| `async` / `await` | `.then()` / `.catch()` chains in the same function |
| `await Promise.all(xs.map(f))` when the calls are independent | `for … await` in sequence without a reason |
| `for (const x of xs) await f(x)` when order or back-pressure matters | `xs.forEach(async …)` |

- Don't mix `await` and `.then` in one function. See `async.md`.

## 9. Iteration & collections

| Canonical | Avoid |
|---|---|
| `for (const x of xs)` | indexed `for` when the index is unused; `for…in` over an array |
| `Object.entries(obj)` / `Object.keys(obj)` | `for…in` with a `keyof` cast |
| `xs.toSorted()`, `toReversed()`, `toSpliced()`, `with()` | in-place `sort` / `reverse` / `splice` on a value you don't own |
| `xs.at(-1)` | `xs[xs.length - 1]` |
| `xs.includes(x)` / `set.has(x)` | `xs.indexOf(x) !== -1` |

- `map` / `filter` / `flatMap` for a pure transformation; a `for…of` loop when there are side effects, early exit, or `await`. A `reduce` that builds an object or needs a comment is a loop.

## 10. Strings

| Canonical | Avoid |
|---|---|
| `` `${name}: ${count}` `` | `name + ": " + count` |
| `parts.join(", ")` | manual concatenation with a trailing-separator loop |

## 11. Class members

- One privacy mechanism per codebase: `private` (compile-time only) or `#field` (enforced at runtime). *Contested*; never both in one class.
- Explicit field declarations plus assignment in the constructor where the project targets erasable syntax (`erasableSyntaxOnly`, Node type stripping); parameter properties only where the project already uses them. Don't mix the two in one class.
- `readonly` on anything not reassigned after construction; `override` on every override.

## 12. Type annotations

| Canonical | Avoid |
|---|---|
| `const user: User = { … }` | `const user = { … } as User` |
| `{ … } as const satisfies Config` to check and keep literals | an annotation that widens what you needed narrow |
| `unknown` + narrowing | `any` |
| `@ts-expect-error — reason` | `@ts-ignore` |

## 13. Quotes, semicolons, layout

- These belong to the formatter — never hand-nit them. If a file isn't formatter-clean, the single finding is "run the formatter".

## Review wording

When you flag a consistency issue, say:
- which canonical form applies,
- that it is a strong default (not a hard rule), and the lint rule name if one exists,
- and whether the file mixes forms (mixing is the stronger finding).

Example: "Suggestion — line 30 defaults with `limit || 50`, so an explicit `limit: 0` becomes 50; the file uses `??` elsewhere (line 52) and `??` is canonical in `consistency.md` (`prefer-nullish-coalescing`). Here it is also a correctness bug, not only style."
