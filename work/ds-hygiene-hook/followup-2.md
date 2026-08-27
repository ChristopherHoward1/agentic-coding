Round 2 review is in: the Claude reviewer APPROVED, Codex requested changes. Both need to
approve before release. The remaining work is test coverage only — no hook logic is wrong.
You are resuming in the same worktree on branch wt/ds-hygiene-hook (gate currently 89/89).

Both reviewers verified your two round-1 fixes independently and confirmed them, including a
GNU-stat stub proving the platform probe now takes the right branch. Nothing to redo there.

Footprint is unchanged: tests/test-scripts.sh, profiles/machine-learning.md, profiles/work.md,
ARCHI.md, scripts/gate.d/examples/ds-hygiene.sh. Do not widen it.

---

## 1 — The empty-prefix skip is load-bearing but untested (both reviewers' strongest point)

`scripts/gate.d/examples/ds-hygiene.sh:35`, `[[ -z "$prefix" ]] && continue`.

Deleting that line causes ZERO test failures. The guard is real: `IFS=: read -r -a` on
`":data/samples"` yields a first field of `""`, and without the skip `case "$path" in ""*)`
matches every path — the exact allow-everything inversion the plan was written to prevent.

Concrete failure it permits: a repo sets `DS_DATA_ALLOW_DIRS=":data/samples"` (stray leading
colon from an edit) and the artifact check silently passes everything, forever, with no test to
notice a future refactor dropped the line.

Add a case: `DS_DATA_ALLOW_DIRS=':data/samples'` against a repo with an oversized file OUTSIDE
both prefixes, expecting exit 1 with that path in stderr. Confirm it fails when line 35 is
removed — that is the whole point of the case.

Related, informational: line 31's empty-`DS_DATA_ALLOW_DIRS` return is doubly load-bearing on
bash 3.2 (macOS default, what the gate runs under). Without it, `"${prefixes[@]}"` on an empty
array is an `unbound variable` hard error under `set -u`, not a wrong answer. It is present and
tested; just don't let a later "simplification" fold it into the loop.

## 2 — Criterion 8's test asserts stderr emptiness but not exit 0 (Codex's finding; Claude concurred)

`tests/test-scripts.sh:806`:

    check "ds hygiene hook skips deleted tracked artifact without stderr" bash -c "... [ -z \"\$(... 2>&1 >/dev/null)\" ]"

`$(...)` discards the hook's exit status entirely, so a hook that exited 1 with silent stderr
would pass. Criterion 8 requires BOTH "exits 0" and "prints nothing to stderr".

Note this is the form the plan itself prescribed (plan.md:125-126), so it is conformant, not
your deviation — the plan was imprecise. Fold in the status check the way your own
"both fail" test at line 762 already does: capture `status=$?`, assert `status -eq 0` AND
empty stderr.

## 3 — Nit, take it: "pre-commit guard" is misleading

`profiles/machine-learning.md:12` and `profiles/work.md:22` both call the hook a "pre-commit
guard". It is a gate hook, not a `.git/hooks/pre-commit` — a reader could install it in the
wrong place. Reword to something like "gate-time guard, run before the commit lands".

## Deliberately NOT in scope — do not fix

- Case-sensitive extension matching (`data/BIG.CSV`). Spec-conformant; leave it.
- `git ls-files` C-quoting paths with newlines/non-ASCII, so they are silently skipped. Same
  behaviour as the existing nb-clean.sh, so it is consistent rather than new. Leave it.
- Allow-dir prefix matching without a separator boundary. The plan specified prefix semantics
  and you already documented it.

---

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. For BOTH new/changed tests, verify they fail when the code they cover is removed. Update the
   ARCHI.md check count to the real number.
3. Commit on this branch.
4. Print a summary including the mutation-check results.
