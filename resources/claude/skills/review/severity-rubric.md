# Severity Rubric

Use this rubric to classify findings consistently.

## Blocking

Use `Blocking` when the issue should realistically stop the PR from merging.

Typical blocking cases:
- correctness bug
- broken invariant
- cross-aggregate mutation in one command handler
- domain/infrastructure boundary violation
- security issue or injection risk
- dangerous persistence / transaction behavior
- materially misleading naming for a core domain concept
- missing regression test for a bug fix
- risky behavioral change without meaningful coverage

Ask:
- Could this create wrong behavior in production?
- Could this create data inconsistency?
- Does this violate a hard architecture rule?
- Would this name cause future code to be built on the wrong abstraction?

## Suggestion

Use `Suggestion` for important improvements that should be fixed but are not severe enough to block on their own.

Typical suggestion cases:
- weak but not catastrophic naming
- handler or service doing too much
- missing edge-case tests on non-critical paths
- maintainability issue that increases future risk
- readability problem that hides intent
- weak timeout / retry posture in a non-critical path
- code that fights project conventions without immediate correctness risk

Ask:
- Does this make the code meaningfully harder to evolve?
- Does it increase the odds of future bugs?
- Is it a strong project convention rather than a hard rule?

## Nit

Use `Nit` for polish that improves clarity or consistency but has low impact.

Typical nit cases:
- small rename
- test naming cleanup
- simplifiable expression
- comment / formatting improvements
- minor API shape refinement

## Confidence

Every finding should include confidence:
- `high`: clear violation or bug
- `medium`: likely issue, but some local context may justify it
- `low`: speculative; raise carefully and explain the uncertainty

## Preference vs rule

Say explicitly when something is a preference or strong default instead of a hard rule.

Good:
- "Suggestion — this does not break a hard rule, but it fights our usual 'no boolean arguments' guideline."

Bad:
- presenting every stylistic preference as if it were a correctness bug
