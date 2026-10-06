# PR Description Style Guide

Write for a human reviewer, not for the project record. A PR description is not documentation, an investigation report or a diff walkthrough. A teammate should understand the problem and the resulting behavior in under 30 seconds.

## Voice

Write like the engineer who implemented the change is explaining it to a teammate. Natural, concise and technical. Use common developer vocabulary. Prefer short sentences and concrete verbs.

Avoid polished or formal transitions such as:

* "This PR introduces..."
* "This change ensures..."
* "This allows..."
* "As a result..."
* "It is worth noting..."
* "In order to..."

Avoid em dashes. If a sentence sounds like release notes, documentation or a design doc, simplify it.

## Default shape

Most PRs are 2 short paragraphs:

1. What is wrong or missing today.
2. What changes after merge.

Use 60 to 120 words. There is no minimum. A trivial PR has an empty body.

Add a third paragraph only for an operational consequence, a compatibility constraint or a reviewer trap that is not obvious from the diff. Use headers only when the PR contains several genuinely independent changes.

## Write about behavior, not implementation

Prefer:

> Existing historical indices do not receive new component-template mappings, so deploying a new field can block ingestion. The release now applies the mapping before deploying the binary.

Not:

> The workflow moves template detection before Docker build, retrieves the secret, calls `apply-templates-via-function.sh`, which sends `action=apply-mapping`...

The diff already tells the reviewer how the code does it. Name classes, functions, files, config keys and commands only when the reviewer needs that name to understand the contract.

## Delete aggressively

Remove a sentence if it only explains:

* how the code is implemented;
* which files changed;
* which helper calls which helper;
* why a local variable, type, interface or class exists;
* test cases, individually;
* commands that passed;
* exact fixture counts;
* exact benchmark numbers, unless performance is the purpose of the PR;
* ticket history or investigation chronology;
* alternatives considered or rejected designs;
* why something is out of scope;
* future work;
* rollout steps already enforced by CI;
* details already obvious from the title;
* facts useful only to prove the author investigated thoroughly.

Do not keep a detail merely because it is technically correct.

## Context

Describe the user-visible, operational or architectural problem. Do not include dates unless timing matters to an incident, sample sizes unless they establish the problem, raw error payloads, production investigation details, implementation archaeology, previous ticket numbers, or more than the minimum example that makes a bug concrete. If one sentence explains the problem, stop there.

## Changes

Describe the new system behavior, not the patch structure.

Good:

> Rule ids now remain strings from the X response through the delete request.

Bad:

> `GnipRule::id`, two Valinor array shapes, the store docblock and the `%s` placeholder now use strings.

Good:

> Code-only releases now reapply the current mapping before deploying.

Bad:

> The secret and apply steps move ahead of the Docker build and their `if` conditions now include `code_changed`.

## Validation

Omit it by default. Mention it only when it tells the reviewer something normal CI cannot: a migration tested against a production-shaped dataset, a compatibility change checked against the real external API, measured results of a performance PR, a data transformation validated over the full corpus. Never list lint, format, unit-test or static-analysis commands. Never enumerate test cases.

## Operational notes

Mention merge or deployment behavior only when a reviewer could otherwise approve something unsafe, in one sentence. No Deployment, Post-deploy, Verification, Testing, Notes or Out of scope sections for ordinary PRs.

## Numbers

Keep a number only when changing or removing it would weaken the explanation. Useful: "the cursor exceeds Nginx's 8 KB request-line limit", "the API allows at most two GPU nodes". Usually useless: document counts, test counts, artifact hashes, commit SHAs, fixture row counts, every measured latency, every host or node involved in an investigation.

**Prefer the invariant over the evidence used to discover it.** Not "100% of 1,500 sampled RSS documents across three indices spanning 15 months had...", but "RSS articles were using crawl time instead of the publication date from the feed." For a GPU node PR the reviewer needs "we provision dedicated GPU nodes for Triton", not zones, disk sizes, image names, replacement strategy or the sequencing of later tickets.

## Titles

The title names the behavior change, not the implementation.

Prefer:

* `feat(inference): provision GPU serving nodes`
* `fix(report): keep X rule ids as strings`
* `fix(historical-ingestor): retry writes rejected by strict mappings`
* `ci(historical-ingestor): apply mapping before the build`

Avoid internal mechanism names when a simpler behavior exists, multiple clauses, counts, versions, instance types or parameter names, words invented during the implementation, and "support", "handle", "improve", "update" when a more precise verb exists. A good title still makes sense six months later without reading the ticket.

## Final deletion pass

Before creating the PR, review every sentence and ask: if I delete this, can a teammate still understand what was broken and what changes after merge? If yes, delete it. Then check:

* Is the body shorter than the first draft?
* Does it describe behavior more than code?
* Did I omit normal test and CI details?
* Did I avoid ticket history and investigation detail?
* Did I avoid repeating the title?
* Did I avoid em dashes?
* Could any paragraph be removed entirely? If yes, remove it.
