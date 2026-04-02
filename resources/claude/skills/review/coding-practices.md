# Coding Practices Review Rules

This file contains PHP and Doctrine conventions used during reviews.

## 1. Class design

### Hard rules

- Prefer composition over inheritance.
- Do not use inheritance for code reuse.
- Do not use traits, except the explicit project exception: `VersionTrait`.
- Use `public` or `private`, never `protected`.
- Services must be stateless.
- Prefer short-lived objects over oversized services.

### Review questions

- Is inheritance being used where composition would be clearer?
- Is a "service" accumulating too many unrelated responsibilities?
- Would a single-use object make the API clearer?

## 2. Readability and control flow

### Strong defaults

- Use guard conditions and early returns.
- Avoid `else`; return early, extract, or use polymorphism.
- Avoid loops inside loops; extract the inner loop or challenge the design.
- Avoid more than 2 levels of indentation.
- Optimize for readability and clarity over cleverness.

### Review guidance

Nested loops and extra indentation are not automatic blockers.
They are signals to look for a clearer decomposition.

## 3. Data shapes and APIs

### Hard rules

- Do not use associative arrays as return values or parameters for structured data.
- Use value objects or result objects instead.
- Initialize properties in the constructor, not inline property declarations.
- All properties must have type hints.
- All parameters and return values must have type hints or PHPDoc where required.
- Use `void` return types when nothing is returned.
- Never use `iterable` as a return type.
- When returning or accepting arrays, document element types.

### Review questions

- Is an array being used as a hidden DTO?
- Is this return type too weak to be safely consumed?
- Are property defaults spread across the class instead of concentrated in the constructor?

## 4. Type assertions

### Rule of thumb

- Prefer `TypeUtils::ensure*` when the value type is unknown at runtime, especially for external, dynamic, or mixed values.
- Use `assert()` to refine local types when that is the clearest option and runtime assertion is appropriate.
- Do not use `@var` as a substitute for a real check.

### Review questions

- Is this value uncertain because of external input, deserialization, or untyped APIs? Prefer `TypeUtils`.
- Is this just local refinement of an already-local variable? `assert()` may be acceptable.
- Is the design forcing callers to do type recovery too often?

## 5. Booleans and conditionals

### Hard rules

- Avoid boolean arguments.
- Prefer separate methods with explicit names.
- Avoid non-exhaustive `switch` / `match`.
- Do not use `default` in `switch` / `match` when exhaustiveness should be enforced.
- Prefer polymorphism or explicit finite types.

### Review questions

- Is a boolean flag hiding two behaviors?
- Is this `match` exhaustive and statically safe?
- Is `instanceof` being used where polymorphism should exist?

## 6. Strings and formatting

### Strong defaults

- Prefer `sprintf()` over interpolation and over messy concatenation.
- Use single-quoted format strings unless escape sequences are needed.

## 7. PHP pitfalls

### Hard rules

- Do not use PHP references unless absolutely unavoidable; unset them afterwards.
- Avoid variable variables.
- Avoid variable class names.
- Avoid broad `instanceof` trees in normal business logic.
- Never catch `\Throwable` or `\Error`.
- After catching an exception, always log it or rethrow it, but not both.
- Never return in `finally`.
- Never expose exception messages to users unless the exception type is explicitly designed for that.

## 8. External requests

### Hard rules

- External requests must use a timeout.
- Retries should be used when appropriate, or rely on clients that already implement retries.
- Reviewers should flag outbound calls without timeout semantics.

## 9. Doctrine and persistence

### Hard rules

- Specify nullability explicitly on Doctrine columns and relations.
- Do not use Doctrine `object` type.
- Do not use `postUpdate` / `postPersist` for work that requires committed data.
- Never use `EntityManager::detach()`.
- Prefer plain DQL over QueryBuilder when the query fits plainly in one string.
- Do not return QueryBuilder from a method.
- Do not pass QueryBuilder between methods.
- For large result sets, prefer pagination patterns that avoid loading everything in memory.

### Review questions

- Is this code relying on detached entities?
- Is the query builder leaking across methods?
- Is this query likely to blow memory?
- Is nullability implicit and therefore ambiguous?

## 10. Serialization and storage

### Hard rules

- Do not use `serialize()` / `unserialize()`.
- Prefer protobuf or JSON depending on the use case.

## 11. Regexes

### Strong defaults

- Use `#` as regex delimiter unless the regex itself contains `#`.
- Use `preg_quote()` when interpolating dynamic values into regexes.

## 12. Promises

### Hard rules

- Promise chains that are not returned should end with `done()`.
- Do not make promise failures silent.

## 13. Commands and long-running processes

### Hard rules

- No infinite loops.
- Long-running Symfony commands must use a time limit mechanism instead of `while (true)`.

## 14. Naming guidance

Naming is a review topic, not an afterthought.

### Flag names that are:

- vague
- overloaded
- technical instead of domain-driven
- implementation-driven
- misleading about ownership or scope

### Common weak names

- `Manager`
- `Service`
- `Handler` when it is not actually a bus/handler role
- `Utils`
- `Processor`
- `Helper`
- `Data`
- `Info`

### Ask:

- What does this object own?
- What action does this method perform?
- Is the name describing the domain or the mechanism?
- Would a future reader predict the same responsibility from the name?
