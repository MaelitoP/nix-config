# Type-System Review Rules

A type is a claim about a runtime value. The compiler verifies most claims; this lens is about the ones it was told to take on faith, and about types that are precise in the wrong place. Grounded in *Effective TypeScript* (Dan Vanderkam) and his blog, Total TypeScript (Matt Pocock), Stefan Baumgartner's fettblog, Alexis King's "Parse, don't validate", the TypeScript handbook ("Do's and Don'ts", Narrowing, Functions) and release notes, the TypeScript performance wiki, and the typescript-eslint rule docs.

## 1. `any`, `unknown`, `never`

### Hard rules

- Never type a value you know nothing about as `any`: `any` switches checking off for every expression it touches, and it spreads. Use `unknown` and narrow. The handbook allows `any` only while migrating from JavaScript.
- A type parameter that appears only in the return type is `any` in disguise: `parse<T>(s: string): T` lets the caller pick a type nothing checks. Return `unknown`, or take a schema. (Vanderkam, "The Golden Rule of Generics".)
- Catch variables are `unknown` (`useUnknownInCatchVariables`, part of `strict`). Narrow with `instanceof` or a guard and keep a fallback branch; a catch clause cannot be annotated with a specific error class, and promise rejections are untyped. (Baumgartner.)
- `JSON.parse`, `response.json()`, and anything from a `no-unsafe-*` lint are `any` at the source. They must be narrowed or parsed before they reach typed code (see §8).

### Strong defaults

- `unknown` is not a blanket replacement for `any`. When a function relates its inputs, the real fix is a constrained generic, not `unknown` plus assertions at every call site. (Pocock, "An `unknown` can't always fix an `any`".)
- When `any` is unavoidable, give it the narrowest scope: on one expression inside a function with a well-typed signature, never on a parameter, return type, or exported symbol. (*Effective TypeScript*: "Use the narrowest possible scope for `any` types", "Hide unsafe type assertions in well-typed functions".)

### Review questions

- Does `any` enter here and flow out through a public signature?
- Is a generic used to let the caller assert a type the function never checks?

## 2. Assertions: `as`, `!`, `@ts-ignore`

### Hard rules

- `as` is unchecked at runtime. Every `as` the diff adds needs a reason a reader can verify; most can be replaced by a conditional, a type guard, `satisfies`, or parsing. `as` used as the default way to type a variable is wrong: annotate the object literal (`const u: User = {…}`), don't assert it. (Vanderkam, "The Seven Sources of Unsoundness"; Pocock; Google style guide.)
- `as unknown as T` is a statement that the types are unrelated. Outside a test fake at an owned seam, treat it as a defect until proven otherwise.
- `!` asserts non-null without a check. Restructure so the compiler can see it (narrow, early-return, or change the model): a `!` on every access is the symptom of an optional-field shape that should be a union (§3). (`no-non-null-assertion`, in typescript-eslint's `strict` preset.)
- No `@ts-ignore` or `@ts-nocheck`. When a suppression is genuinely needed, `@ts-expect-error` with a one-line reason, so it fails once the error is gone.
- A hand-written type predicate (`x is T`) or assertion function (`asserts x is T`) is an assertion: the compiler trusts the body without checking it. Its body must actually establish the claim.

### Strong defaults

- Prefer inferred type predicates (TS 5.5): `xs.filter(x => x !== undefined)` narrows with no annotation. Inference needs "if and only if" semantics, so `x => !!x` does not narrow `number | undefined`. Hand-written `(x): x is T => x != null` helpers and `filter(Boolean)` as a narrowing device are superseded.
- Wrong third-party types get fixed upstream or by module augmentation, not by an assertion at each call site.

### Review questions

- For each `as` / `!` in the diff: what guarantees it at runtime, and where is that enforced?
- Would the code still be correct if the asserted value were `undefined`?

## 3. Model the states, not the fields

### Hard rules

- Variants are a union of object types with a literal tag, not one type with optional fields. A bag of optionals admits combinations that mean nothing and forces `!` downstream. (Handbook, Narrowing; *Effective TypeScript*: "Prefer types that always represent valid states", "Prefer unions of interfaces to interfaces with unions".)
  ```ts
  // Wrong: { kind: "circle" } with a sideLength type-checks
  interface Shape { kind: "circle" | "square"; radius?: number; sideLength?: number }
  // Right
  type Shape =
    | { kind: "circle"; radius: number }
    | { kind: "square"; sideLength: number };
  ```
- Every `switch` (or `if` chain) over a union tag ends in an exhaustiveness check, so a new member is a compile error rather than a silent fall-through. (`switch-exhaustiveness-check`.)
  ```ts
  default: {
    const unreachable: never = shape;
    throw new Error(`unhandled shape: ${JSON.stringify(unreachable)}`);
  }
  ```

### Strong defaults

- Related booleans (`isLoading`, `isError`, `data?`) are one state union.
- An untagged union `A | B` is inclusive: a value carrying both members' properties satisfies it. Prefer a tag; `otherProp?: never` is the fallback and is only fully closed under `exactOptionalPropertyTypes`. (Vanderkam, "Exclusive Or and the Optional `never` Trick".)
- Tighten values: a literal union instead of `string`, a branded type for an ID or a validated value (the cast lives in the one function that validates). Brands are opt-in ("*Consider* brands"), worth it where two same-shaped primitives must not be swapped.
- Prefer an imprecise type to an inaccurate one: a type that rejects valid values is worse than one that is merely wide. (*Effective TypeScript*.)

### Review questions

- Can I construct a value of this type that the code does not handle?
- Was a union member added without touching every `switch` over it?

## 4. Optional, `null`, `undefined`

### Strong defaults

- Push nullability to the perimeter: resolve absence once, at the edge, and pass non-nullable values inward. A type alias does not embed `| null` / `| undefined`; the use site adds it. (*Effective TypeScript*; Google style guide.)
- Limit optional properties. Each `?` doubles the states a reader must consider; an optional that is always supplied should be required.
- `prop?: T` (may be absent) and `prop: T | undefined` (must be passed, may be undefined) are different contracts. They are only distinguishable under `exactOptionalPropertyTypes`; without the flag, don't write code that depends on the difference.
- Index access can be absent. Under `noUncheckedIndexedAccess` the checker says so; without it, `arr[i]` and `record[key]` are typed `T` while being `T | undefined`. Narrow the result, or avoid the lookup (`for…of`, `Map.get`, `.at()`).
- One absence value per codebase (see `consistency.md`).

## 5. Generics discipline

### Hard rules

- The golden rule: a type parameter relates the types of two or more things. One that appears once should be removed or replaced by its constraint. An appearance in an inferred return type counts as a use. (Vanderkam; handbook, "Type parameters should appear twice".)
  ```ts
  function printProp<T, K extends keyof T>(o: T, k: K) {}   // K appears once
  function printProp<T>(o: T, k: keyof T) {}
  ```
- Every declared type parameter is used. (Handbook, "Do's and Don'ts".)

### Strong defaults

- Push type parameters down: `<T>(xs: T[])`, not `<A extends unknown[]>(xs: A)`. Use as few as possible.
- `NoInfer<T>` (TS 5.4) instead of a dummy second type parameter to stop a position from being an inference site.
- `const` type parameters (TS 5.0) instead of asking every caller for `as const`: `<const T extends readonly string[]>`.
- Type-level complexity is paid by every caller in error messages and by the compiler on every call. Name a complex conditional type instead of inlining it, and ask whether a plain union or a little repetition would do: "a little bit of repetition or verbosity is often much cheaper than the long term cost of complex type expressions" (Google style guide). When types get elaborate, consider generating them (*Effective TypeScript*: "Consider codegen as an alternative to complex types").
- Unions before overloads: prefer a union-typed parameter to overloads, optional parameters for trailing-arity differences, overloads only when the return type depends on the input, most specific first. (Handbook.)

### Review questions

- Does each type parameter relate two things, or is it decoration?
- Would a reader understand the error message this type produces?

## 6. `satisfies`, annotation, inference

### Strong defaults

- Annotate (`const x: T = …`) when you want the declared, wider type. Use `satisfies T` when you want the value checked against `T` but keep its precise inferred type, typically with `as const`. Most locals need neither. (Pocock, "Clarifying the `satisfies` operator".)
  ```ts
  const routes = { home: "/", user: "/u/:id" } as const satisfies Record<string, string>;
  ```
- Don't annotate what the compiler infers correctly inside a function (*Effective TypeScript*: "Avoid cluttering your code with inferable types").
- Do annotate the return type of exported, top-level functions: it pins the public contract, keeps errors at the definition instead of the call sites, saves the compiler work, and is required under `isolatedDeclarations`. Exception: a function meant to be an inferred type predicate (§2) must leave it off. (TS performance wiki; Pocock; contested for internal functions, so calibrate to the codebase.)

## 7. Derive, don't duplicate

### Strong defaults

- One source of truth per shape. Derive the rest: `typeof` a value, `keyof`, indexed access (`Order["status"]`), `(typeof ROLES)[number]`, `Partial<typeof defaults>`, `ReturnType`, `z.infer`. A hand-copied type drifts. (Baumgartner, "Low maintenance types".)
- Derive only between types that share a concern. A UI prop type derived from a database row couples two things that change for different reasons; decouple those. (Pocock.)
- Export every type that appears in a public signature. (*Effective TypeScript*.)

## 8. Trust boundaries: parse, don't assert

### Hard rules

- Data from outside the type system (HTTP bodies, `JSON.parse`, env vars, storage, queue messages, database rows, `postMessage`) has no type until something checks it. `as ApiResponse` on it is a lie with a delay; `interface` declarations do not validate. Parse it once at the boundary with a schema or a type guard, and pass the parsed type inward. (King, "Parse, don't validate"; Vanderkam.)
  ```ts
  const User = z.object({ id: z.string(), email: z.email() });
  type User = z.infer<typeof User>;

  const user = User.parse(await res.json());
  ```
- A check that returns nothing throws its knowledge away. `validateUser(x): void` followed by `x as User` is the anti-pattern; `parseUser(x): User` is the fix.

### Strong defaults

- The schema is the source of truth and the type is inferred from it; a hand-written interface beside a schema is two definitions that can disagree.
- Decide the failure mode deliberately: `parse` throws, `safeParse` returns a result union. Once a schema transforms, its input and output types differ (`z.input` / `z.output`).
- A library accepting user schemas should accept Standard Schema rather than one validator.
- In application code, `ts-reset` makes `JSON.parse` / `.json()` return `unknown`. It patches global types, so never in a library.

### Review questions

- Where does this value first enter the program, and what checked it there?
- Is the same data validated in three places, or parsed once?

## 9. Types to never write

### Hard rules

- No `Number`, `String`, `Boolean`, `Symbol`, `Object`: the lowercase primitives and `object`. (Handbook.)
- `{}` means "any non-nullish value", not "empty object". For an empty object, `Record<string, never>`; for "some object", `object` or a real shape. (Pocock.)
- No `Function`: calling it returns `any`. Write the signature. (`no-unsafe-function-type`.)
- Callback types return `void` when the result is ignored, and don't mark callback parameters optional. (Handbook.)
- No `namespace` for code organisation (ES modules), no `enum` in new code (see `consistency.md`). Declaration merging is for augmenting globals and libraries only.

## 10. `readonly` and structural surprises

### Strong defaults

- Array and object parameters a function does not mutate are `readonly` (`readonly T[]`, `Readonly<T>`): it documents the contract, accepts more callers, and closes the array-covariance hole. `Readonly` is shallow.
- Excess-property checks apply only to fresh object literals. A value routed through a variable can carry extra properties, so `Object.keys(x)` is `string[]`, and a `for…in` key cast to `keyof T` is false certainty. Iterate `Object.entries`, or use a `Map` for a real key/value collection. (Vanderkam.)
- Narrowing survives a function call that could have mutated the object. Copy a property to a local `const` before a callback or an `await` that the narrowing must outlive.

## 11. What makes a type finding blocking

Usually blocking:
- external data asserted (`as`) into a domain type instead of parsed
- `any` leaking through an exported signature, or a return-only generic
- `as` / `!` / `as unknown as` over a value that can really be absent or of another type
- a union member added with a `switch` that silently falls through
- `@ts-ignore` / `@ts-nocheck`, or a loosened compiler flag, hiding a real error
- a hand-written type predicate whose body does not establish the claim

Usually suggestion:
- an optional-field bag that should be a discriminated union
- a type parameter that appears once; type gymnastics a union would replace
- duplicated shapes that should be derived; a derived type coupling unrelated concerns
- missing `readonly` on inputs; `string` where a literal union or brand fits
- a missing return type on an exported function
- a mutable or optional property that is always set

Usually nit:
- an inferable annotation
- a type alias or type parameter name
