# Security and Safety Review Rules

This file defines security-focused review checks.

## 1. Escaping

### Hard rules

- Escape output, not input.
- Never require callers to pre-escape values.
- Always use safe parameterization/escaping at the point where the value is embedded into:
  - SQL
  - HTML
  - URLs
  - shell commands
  - regexes
  - any other interpreted format

### Blocking examples

- string-concatenated SQL with user or dynamic input
- shell command assembled with unescaped variables
- regex built from dynamic input without `preg_quote()`

## 2. SQL

### Hard rules

- Always use prepared statements / parameters.
- Never trust validation like `intval()` as a replacement for parameterization.

## 3. Exception handling and user exposure

### Hard rules

- Do not expose raw exception messages to users.
- Catching must not silently swallow errors.
- Caught exceptions must be logged or rethrown.

## 4. External requests

### Hard rules

- All outbound requests must have a timeout.
- Retries should exist when appropriate and safe.
- Avoid retrying clearly permanent failures.

### Review questions

- Can this call hang forever?
- Is retry policy missing or inappropriate?
- Is this path safe under transient failure?

## 5. Persistence and consistency hazards

Flag:
- work performed before a transaction is committed when the code assumes committed state
- lifecycle hooks used in ways that assume post-commit guarantees
- event dispatch or side effects that can be lost or duplicated without the right guarantees

## 6. Dangerous PHP / Doctrine / shell patterns

Flag:
- `serialize()` / `unserialize()`
- raw shell commands with concatenated args
- `detach()`
- hidden promise rejections
- broad catch blocks that suppress failures

## 7. Review severity guidance

Blocking:
- injection risk
- unsafe external request likely to hang forever
- silent exception swallowing in critical path
- persistence/event ordering bug with real consistency risk

Suggestion:
- missing retry where failure is tolerable but resilience is weak
- weak logging around transient failures
- low-risk escaping issue in an internal-only path

Nit:
- small hardening improvement with no realistic exploit or correctness risk
