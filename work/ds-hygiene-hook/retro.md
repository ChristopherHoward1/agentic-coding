# Retro — ds-hygiene-hook (v2026.8.9)

Released 2026-08-27. Three plan-review rounds, three code-review rounds, one gate-fix
dispatch. Both reviewers APPROVE; gate 90/90.

## What did the gate miss that a reviewer caught?

**An inverted `stat` platform probe that silently disabled the artifact check on Linux.**
The gate ran green at 87/87 on macOS while `file_size_bytes` was broken everywhere else:
the probe assumed GNU `stat` fails on `-f %z`, but `-f` means `--file-system` there, an
unknown directive prints `?` and exits 0. On Linux `size` became `?`, the `-gt` comparison
aborted, and the hook reported clean while never checking anything.

The gate cannot catch this by construction — it runs on one platform per invocation. CI
would have gone red on push, but only after the release commit was built. What actually
caught it was a reviewer stubbing a coreutils-shaped `stat` on `PATH` and running the hook
against it. That technique is the durable part.

→ **contextual.** Folded into `knowledge/test-helper-contract.md` as the platform-stub
section, since the same doc covers how this suite proves things.

## What did every check miss?

**Three tests that passed with the code they covered deleted**, across two rounds:
criterion 7's disable guard (round 1), the empty-prefix skip and criterion 8's exit status
(round 2). Each was found by a reviewer deleting a line and re-running, never by the gate —
a green suite is indistinguishable from a vacuous one.

The third round's 13-mutation sweep found no further vacuous DS tests, but it did find
`/home/` in the path regex is still uncovered: its fixture asserts exit 0 under
`DS_PATH_SCAN=''`, so it passes whether or not the alternative exists.

→ **process.** One line in `PLAN.md → Decisions`: a test asserting a guard exists is not
done until it has been shown to fail with that guard removed.

Three non-blocking findings shipped knowingly (non-numeric `DS_DATA_MAX_BYTES` disables the
check while the gate stays green; the uncovered `/home/` alternative; case-sensitive
extension matching). They are recorded in `work/ds-hygiene-hook/plan.md` → Code review and
belong to the deferred follow-up unit. Not duplicated here.

## What got re-derived that a doc would have prevented?

**The `tests/test-scripts.sh` helper contract, three separate times.** `check` and
`check_fails` discard both streams; `check_exit` greps stderr only; nothing in the helper
set asserts absence, emptiness, or a combination of status and output. This shaped a plan
decision (diagnostics must go to stderr), then was re-derived in plan round 2 (the "no new
helper" claim needed narrowing), then again in code-review rounds 2 and 3 (criterion 8's
test discarded its exit status — in the form the plan itself had prescribed).

Each rediscovery cost a review round. The contract is stable, non-obvious, and lives only
in the helper bodies.

→ **contextual.** New `knowledge/test-helper-contract.md`.

## What friction repeated from a prior retro?

**The implementer could not commit its own work.** `codex exec --sandbox workspace-write`
is denied write access to the parent repo's git metadata from inside a worktree:
`fatal: Unable to create .../.git/worktrees/ds-hygiene-hook/index.lock: Operation not
permitted`. The Orchestrator committed after independently re-running the gate, which
`/2-implement` step 6 permits — but it means every dispatch ends with the writer/committer
boundary blurred, and `agent-exec.sh`'s null-dispatch detection (added in `loop-hardening`,
v2026.8.8) is reasoning about a tree the implementer was never able to commit.

This is adjacent to `loop-hardening`'s open `agent-exec-noop-scope` candidate and touches
`scripts/`, which this branch may not edit.

→ **`/1-plan` unit, not applied here:** `codex-worktree-commit` — either grant the sandbox
the worktree's git metadata path or make Orchestrator-side commit the documented contract
rather than a fallback, and reconcile with `agent-exec-noop-scope` since both concern what
`agent-exec.sh` may assume about the tree it gets back.

**Review churn, refined rather than repeated.** The 2026-08-27 `loop-hardening` lesson was
that a reviewer's "drop this marginal fix" is a cost signal. This unit spent three rounds at
each of plan and review and the spend was worth it — round 1 of code review caught a bug
that would have shipped a hook that silently does nothing on Linux. The prior lesson holds
for *marginal* findings; it does not generalise to round count.

→ **not worth keeping** as a separate entry. Adding a second, hedging line next to the
existing one would blunt both. The existing `PLAN.md` line already says "marginal fix", and
that word is doing the work.

## Not worth keeping

- The `:=` vs `=` parameter-expansion slip (round 1 prescribed `:=`, round 2 caught that it
  refills an emptied knob). The reviewer self-corrected inside the loop at a cost of one
  round, and documenting bash expansion semantics is not this repo's job.
