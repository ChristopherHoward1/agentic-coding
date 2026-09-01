# Retro — s3-owner-scope (loop-skipping fixes)

Two direct edits to `profiles/work.md`, shipped on `fix/s3-owner-scope`, no work unit:
1. `<user>` resolved per-write from the environment instead of baked in at /init.
2. `<user>` generalized to `<owner-scope>` — a person *or* a `shared/` namespace — plus rule 4
   requiring shared writes to partition by writer/run.

These skipped the loop deliberately (CLAUDE.md small-fix carve-out). No gate ran, no reviewer,
so the first three questions have no loop artifacts to mine — answered on their merits below.

## What did the gate miss that a reviewer caught?

N/A — no gate, no reviewer. The fixes are doc text, not code with a gate.

## What did every check miss?

**The original profile baked a single-tenant assumption into a shared-resource convention.**
`s3://<bucket>/<user>/{project}/` declared one user at /init, which is invisible until a second
person shares the framework — exactly the case the profile exists to standardize. The Owner
surfaced it, not any check. But this is self-correcting: the assumption lived in the profile and
the fix lives in the same profile. Nothing durable to add elsewhere.

→ **not worth keeping.** The lesson *is* the edit; recording "watch for single-tenant
assumptions" as a separate artifact would be the essay-decision PLAN.md forbids.

## What got re-derived that a doc would have prevented?

Nothing. The profile is the doc; both fixes edited it in place.

## What friction repeated from a prior retro?

None. First retro touching the S3 discipline.

## Note (not a routed lesson)

Fix 1 under-scoped: "identify the user" and "scope the write" are different axes (identity vs.
ownership boundary), and only the Owner's follow-up question surfaced the shared-write case that
made fix 2 necessary. Worth noticing that a one-line fix to a *convention* can hide a second axis
— but the two edits together already encode the distinction (`<bucket>` = ownership boundary,
`<owner-scope>` = writer within it). Not worth a durable entry.

## Routing summary

- All four questions → **not worth keeping**, with reasons above. No `gate.d/`, `knowledge/`, or
  `PLAN.md` change. "Nothing learned" is a valid retro; this is close to one.
