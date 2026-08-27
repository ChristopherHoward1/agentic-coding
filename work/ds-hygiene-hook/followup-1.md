Code review found two blocking defects in your implementation of work/ds-hygiene-hook/plan.md.
You are resuming in the same worktree on branch wt/ds-hygiene-hook. The gate currently PASSES
(87/87) — that is part of the problem: finding 2 is a vacuous test that hides finding 1 on Linux.

Stay inside the plan's footprint (scripts/gate.d/examples/ds-hygiene.sh, tests/test-scripts.sh,
profiles/machine-learning.md, profiles/work.md, ARCHI.md). Do not widen scope.

---

## BLOCKING 1 — `file_size_bytes` platform probe is inverted; the artifact check silently dies on Linux

`scripts/gate.d/examples/ds-hygiene.sh:11-19`:

    if stat -f %z "$path" >/dev/null 2>&1; then
      stat -f %z "$path"
    else
      stat -c %s "$path"
    fi

The probe assumes GNU `stat` FAILS on `-f %z`. It does not. On GNU coreutils `-f` means
`--file-system`, and an unrecognized directive falls through `print_statfs`'s
`default: fputc('?', stdout)` — it prints `?` and exits **0**. So on Linux the probe succeeds,
`size` becomes `?`, and `stat -c %s` is never reached. The comparison then aborts:

    $ bash -uo pipefail -c 'size="?"; [[ "$size" -gt 10 ]]; echo rc=$?'
    bash: [[: ?: syntax error: operand expected (error token is "?")
    rc=1

Consequences: (a) `.github/workflows/ci.yml` runs on ubuntu-latest — the four artifact cases
expect exit 1 and would get exit 0, so the suite goes red on push; (b) worse in production, a
Linux DS repo copying this hook gets an artifact check that NEVER FIRES while printing
`[[: ?: syntax error` on every gate run — a hook reporting "clean" while a 4GB parquet lands.
ARCHI.md commits the stack to macOS **and** Linux, so this is in scope.

Verified on this macOS box: `stat -c %s <file>` exits 1 cleanly with "illegal option -- c",
and `stat -f %z <file>` returns the size. So the order-swap works here:

    size=$(stat -c %s "$path" 2>/dev/null || stat -f %z "$path")

Either that, or drop `stat` entirely for `wc -c <"$path"` — note `wc` emits leading whitespace
on macOS, so strip it or rely on bash arithmetic tolerating it deliberately, not by accident.
Your call; make it robust on both platforms.

## BLOCKING 2 — the test for acceptance criterion 7 is vacuous

`tests/test-scripts.sh:729`, `ds hygiene hook still flags local path when artifact scan is
disabled`, asserts exit 1 on a fixture containing BOTH an oversized artifact AND a bad path.
Exit 1 arrives from the path scan regardless of whether the artifact check is disabled,
crashing, or firing normally. The reviewer proved it: deleting
`[[ -z "$DS_DATA_MAX_BYTES" ]] && return 0` from ds-hygiene.sh:52 leaves the suite at
**87 passed, 0 failed**.

The plan (plan.md:206-209) calls that guard "the likeliest way the implementation trips;
criterion 7 catches it." It does not. The implementation is correct; the test is not.

Add a case shaped like the existing `DS_PATH_ONLY_REPO` one: an ARTIFACT-ONLY fixture (no bad
paths) with `DS_DATA_MAX_BYTES=''`, asserting exit 0. Note this also mutation-kills finding 1
on Linux but NOT on macOS, so it does not substitute for actually fixing finding 1.

## MINOR 3 — no case exercises both checks failing at once

`fail=0; check_data_artifacts || fail=1; check_local_paths || fail=1` (ds-hygiene.sh:86-89) is
the only place the two return values combine, and every current case exercises one arm. Add one
fixture violating both, asserting exit 1 with both paths named in stderr.

## NITS — fix only if free; do not expand the diff for them

- Extension matching is case-sensitive: `data/BIG.CSV` is not flagged. Spec-conformant (the plan
  lists lowercase globs) but a real DS repo will hit it. If you fix it, say so in the summary.
- `DS_DATA_ALLOW_DIRS=tests/fixtures` also exempts `tests/fixtures-archive/huge.csv` — prefix
  matching with no separator boundary. The plan specified prefix semantics, so leave the
  behaviour alone, but add one clause to the profile prose so adopters are not surprised.
- `profiles/machine-learning.md:23` repeats the "hooks run on every gate regardless of
  `profile:`" sentence already present in the REPO_HYGIENE bullet at line 12. Drop one.

---

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Sanity-check that your finding-2 test actually fails when the guard is removed. A test that
   passes with the code deleted is not a test.
3. Commit on this branch.
4. Print a summary: what changed, which nits you took, anything you deliberately left.
