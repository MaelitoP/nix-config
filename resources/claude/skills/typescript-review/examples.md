# Example Review Comments (TypeScript)

Use these as a tone and quality reference. Terse, concrete, with an idiomatic fix.

## Good example — Unparsed external data (blocking)

- **File:** `src/billing/client.ts:31`
- **Title:** API response is asserted to `Invoice`, never checked
- **Why it matters:** `(await res.json()) as Invoice` converts nothing: `json()` returns `any`, and the assertion only tells the checker to stop looking. When the upstream renames `amountDue`, every consumer reads `undefined` as a number and the failure surfaces three modules away.
- **Recommendation:** Parse at the boundary and infer the type from the schema:
  ```ts
  const Invoice = z.object({ id: z.string(), amountDue: z.number().int() });
  type Invoice = z.infer<typeof Invoice>;

  const invoice = Invoice.parse(await res.json());
  ```
- **Confidence:** high

## Good example — Floating promise in a loop (blocking)

- **File:** `src/sync/push.ts:18`
- **Title:** `forEach(async …)` returns before any record is pushed
- **Why it matters:** `forEach` ignores the promises its callback returns, so `pushAll` resolves immediately, the caller reports success, and a rejected `push` becomes an unhandled rejection that takes the process down. (`no-misused-promises`.)
- **Recommendation:** Await the work. Sequential if order or rate limits matter, otherwise concurrent with a bound:
  ```ts
  for (const record of records) {
    await push(record);
  }
  ```
- **Confidence:** high

## Good example — Check-then-act across an `await` (blocking)

- **File:** `src/auth/token-cache.ts:12`
- **Title:** Concurrent callers each refresh the token
- **Why it matters:** `if (!token) token = await refresh()` checks, then yields. Every request arriving during the refresh also sees no token and starts its own, and the last one to finish wins; with single-use refresh tokens all but one fail. (`require-atomic-updates`.)
- **Recommendation:** Cache the promise instead of the result, so every caller shares one refresh, and drop it on failure so the next call retries:
  ```ts
  let token: Promise<Token> | undefined;

  function getToken(): Promise<Token> {
    token ??= refresh().catch((err: unknown) => {
      token = undefined;
      throw err;
    });
    return token;
  }
  ```
- **Confidence:** high

## Good example — `||` discarding a valid value (blocking)

- **File:** `src/search/query.ts:44`
- **Title:** `limit || 20` turns an explicit `limit: 0` into 20
- **Why it matters:** `0` is a documented value here ("count only, return no rows"), and `||` treats it as missing. The request succeeds with the wrong page size; no test covers `0`.
- **Recommendation:** `const limit = options.limit ?? 20;` and add the `limit: 0` case to the test table. (`prefer-nullish-coalescing`.)
- **Confidence:** high

## Good example — Non-exhaustive union (blocking)

- **File:** `src/orders/status-label.ts:9`
- **Title:** New `"refunded"` status falls through to the `default` label
- **Why it matters:** This PR adds `"refunded"` to `OrderStatus`, but `statusLabel` ends in `default: return "Unknown"`, so the new status compiles and renders "Unknown". Nothing will flag the next member either.
- **Recommendation:** Handle the case and make the `default` unreachable so the compiler finds the next one:
  ```ts
  default: {
    const unreachable: never = status;
    throw new Error(`unhandled status: ${String(unreachable)}`);
  }
  ```
- **Confidence:** high

## Good example — Modelling (suggestion)

- **File:** `src/upload/state.ts:5`
- **Title:** `UploadState` allows `isDone` with an `error`
- **Why it matters:** Three booleans and two optionals describe eight combinations, of which four are meaningful; the component already needs `state.url!` to get at a value the type says may be missing.
- **Recommendation:** A discriminated union makes the invalid combinations unrepresentable and removes the `!`:
  ```ts
  type UploadState =
    | { status: "idle" }
    | { status: "uploading"; progress: number }
    | { status: "done"; url: string }
    | { status: "failed"; error: UploadError };
  ```
- **Confidence:** high

## Good example — Generic that isn't (suggestion)

- **File:** `src/config/load.ts:22`
- **Title:** `loadConfig<T>(): T` is an assertion wearing a type parameter
- **Why it matters:** `T` appears only in the return type, so each caller picks a type nothing verifies; it is `as T` moved to the call site.
- **Recommendation:** Return `unknown` and parse, or take the schema and infer from it:
  ```ts
  function loadConfig<S extends z.ZodType>(schema: S): z.infer<S> {
    return schema.parse(readRawConfig());
  }
  ```
- **Confidence:** high

## Good example — Test that cannot fail for the right reason (blocking)

- **File:** `src/retry/retry.test.ts:27`
- **Title:** Regression test passes with the fix reverted, and sleeps
- **Why it matters:** The fix makes the first retry wait 2s instead of firing immediately, but the test awaits `sleep(100)` and asserts `toHaveBeenCalled()`. Reverting the fix leaves it green, and the real timer makes it timing-dependent.
- **Recommendation:** Drive time explicitly and assert the schedule:
  ```ts
  vi.useFakeTimers();
  const op = vi.fn().mockRejectedValueOnce(new Error("busy")).mockResolvedValue("ok");

  const result = retry(op);
  await vi.advanceTimersByTimeAsync(1_999);
  expect(op).toHaveBeenCalledTimes(1);
  await vi.advanceTimersByTimeAsync(1);
  expect(op).toHaveBeenCalledTimes(2);
  await expect(result).resolves.toBe("ok");
  ```
- **Confidence:** high

## Good example — Consistency clearly labeled (suggestion)

- **File:** `src/users/roles.ts:4`
- **Title:** New `enum Role` beside literal-union types
- **Why it matters:** The module models every other closed set as a union (`Plan`, `Region`); this adds a second idiom for the same concept, emits runtime code, and will not run under the repo's `erasableSyntaxOnly`.
- **Recommendation:** `type Role = "owner" | "member" | "guest"`, or an `as const` object if the values are iterated at runtime. Canonical form in `consistency.md` §4; strong default, not a hard rule.
- **Confidence:** medium

## Good example — Design question handed off

- **File:** `src/payments/charge.ts:40`
- **Title:** `charge()` throws for a declined card
- **Why it matters:** A decline is an ordinary outcome every caller must handle, but the signature `Promise<Receipt>` hides it; two of the three call sites have no `catch`.
- **Recommendation:** Either return a discriminated result for the expected failures, or keep throwing and fix the callers. The module currently does both in different functions.
- **Confidence:** medium
- → `/typescript-expert Should expected payment failures be a returned result union or thrown errors in this module?`

## Bad example

> This type could be stricter and you should probably await that.

Why this is bad:
- no file/line
- no explanation of impact
- no concrete idiomatic fix
- no severity, no confidence
