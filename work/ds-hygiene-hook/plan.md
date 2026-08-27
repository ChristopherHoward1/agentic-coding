# DS hygiene gate hook

**Slug:** ds-hygiene-hook · **Date:** 2026-08-27 · **Status:** draft

## Goal

Data-science repos rot in predictable, mechanical ways. Two of those ways cause damage
that is expensive or impossible to undo: committing datasets and model artifacts (which
bloats the repo permanently, since history keeps the blob after the file is deleted), and
baking absolute local paths like `/Users/someone/data` into code (which works for the
author and breaks for everyone else). Today the framework answers only the notebook slice
of repo hygiene — `gate.d/examples/nb-clean.sh` plus the ML profile's NOTEBOOK_STRATEGY.
Done means one opt-in gate hook that fails on these two conditions with output naming the
offending path, hermetic tests for it, and both the `machine-learning` and `work` profiles
pointing at it.

Deliberately out of scope: secret scanning, a Python file-length cap, and a `scripts/`
manifest requirement. Each carries a policy judgment — regex false-positive rate, an
arbitrary line threshold, a manifest convention this repo itself would currently fail —
that is better made against evidence from a repo actually running the hook. See
`## Deferred` below.

## Approach

One example hook, `scripts/gate.d/examples/ds-hygiene.sh`, modelled on `nb-clean.sh`: not
wired in by default, copied to `scripts/gate.d/ds-hygiene.sh` by repos that want it,
`cd`s to the repo root, sources truth from `git ls-files`, exits 1 on any violation.

**Diagnostics go to stderr, not stdout.** `nb-clean.sh` prints to stdout, but
`tests/test-scripts.sh:6-21` shows `check`/`check_fails` discard both streams and only
`check_exit` greps — and it greps *stderr*. Writing to stderr lets the tests assert the
offending path with `check_exit "$desc" 1 "path/to/file" …` and no new helper. `gate.sh`
captures both streams, so implementer feedback is unaffected.

**Config knobs are env-overridable defaults**, so they can be set either by editing the
copied hook or from the environment (the tests rely on the latter):

```sh
: "${DS_DATA_MAX_BYTES=1048576}"
: "${DS_DATA_ALLOW_DIRS=tests/fixtures}"   # colon-separated path prefixes
: "${DS_PATH_SCAN=1}"
```

Note the colon-less `=`, not `:=`. `:=` substitutes when a variable is unset **or null**,
so an emptied knob would be silently refilled with its default and could never disable
anything; `=` substitutes only when unset, which is what the disable contract needs.
Plain `VAR=value` assignment must not be used either — it clobbers the environment and
would break both the tests and any CI override.

Emptying a knob disables its check: `DS_DATA_MAX_BYTES=""` disables the artifact check and
`DS_PATH_SCAN=""` the path check. `DS_DATA_ALLOW_DIRS=""` is different and must not follow
that pattern — it means **no allowed directories**, i.e. check everything. The naive
`case "$path" in "$prefix"*)` matches every path when the prefix is empty, which would
invert the knob into "allow everything"; the implementation must skip empty prefixes.

The two checks, over tracked files only:

1. **Data/model artifacts** — tracked files matching `*.csv *.tsv *.parquet *.pkl
   *.pickle *.h5 *.hdf5 *.onnx *.joblib *.npy *.npz` whose working-tree size exceeds
   `DS_DATA_MAX_BYTES` and whose path does not start with one of `DS_DATA_ALLOW_DIRS`.
   Working-tree size (not blob size) is the right measure: it flags the file on the gate
   run *before* the commit makes it permanent, which is the only cheap moment. A tracked
   path missing from the working tree is skipped rather than treated as an error — which
   means the hook goes quiet once someone `git rm`s an already-committed blob, exactly the
   history-bloat case the Goal opens with. That is the accepted trade for a pre-commit
   gate; the profile prose must not promise recovery of already-committed artifacts.
2. **Hardcoded local paths** — `/Users/`, `/home/`, and `C:\` in tracked `*.py` and
   `*.ipynb`. Scoped to those two extensions on purpose: broadening to `*.sh`/`*.md`
   would flag this repo's own profile prose and work-unit plans.

Regexes use POSIX classes (`[[:space:]]`, not `\s`) — `\s` is a GNU/ugrep extension that
stock BSD `grep -E` on macOS does not honour, and ARCHI commits the stack to macOS/Linux.

**Profiles.** `machine-learning.md` gains a `REPO_HYGIENE` declaration alongside the
existing eval slots, naming the hook, its copy-in path, and the two knobs a repo must
decide. `work.md` gains a short section pointing at `machine-learning.md`'s
NOTEBOOK_STRATEGY and REPO_HYGIENE — an addition, not a de-duplication, since `work.md`
has no notebook-hygiene prose today (its only notebook mention is the Snowflake skeleton).
The pointer is necessary because `config.yaml` selects exactly one profile with no
merging, so a work repo would otherwise never learn the hook exists. Both profiles state
that `gate.d/` hooks run on every gate regardless of `profile:`.

**ARCHI.md** is in footprint because `release.sh check_archi_fresh` (line 118) compares
ARCHI's last commit against `scripts/ skills/ profiles/ config.yaml CLAUDE.md`.

## Footprint

Files to modify:
- `scripts/gate.d/examples/ds-hygiene.sh` (new)
- `tests/test-scripts.sh` (new hermetic fixture + cases, placed after the nb-clean block)
- `profiles/machine-learning.md`
- `profiles/work.md`
- `ARCHI.md` — four edits: the `gate.d/examples/` sentence (names only `nb-clean.sh`), the
  `profiles/` summary line (ML profile contents), the `tests/test-scripts.sh` inventory
  sentence, and the `76 checks` count under Verification.

Files NOT to touch:
- `scripts/gate.d/` proper — the hook ships as an example, never auto-enabled here.
- `scripts/gate.sh` — hook discovery already works.
- `config.yaml` — no new knob; policy lives in the copied hook.

## Acceptance criteria

- [ ] `scripts/gate.d/examples/ds-hygiene.sh` exists, passes `shellcheck`, uses
      `set -uo pipefail`, `cd`s to `git rev-parse --show-toplevel`, and declares all three
      knobs with the colon-less `: "${VAR=default}"` (not `:=`, not plain assignment).
- [ ] Hermetic fixture repo, artifact check: with `DS_DATA_MAX_BYTES` lowered so the
      fixture stays small, the hook exits 1 and stderr names the oversized `.parquet` path.
- [ ] The allowed-dir exemption holds: an equally-sized `.csv` under `tests/fixtures/` is
      absent from the hook's output. `check_exit` asserts substring *presence* only, so
      this one case needs an inline absence assertion rather than the standard helper —
      `check "$desc" bash -c 'out=$(bash hook 2>&1); ! grep -q allowed.csv <<<"$out"'`.
      Every other criterion here uses the existing helpers unchanged.
- [ ] `DS_DATA_ALLOW_DIRS=""` means no allowed directories, not all: with it empty, that
      same oversized `.csv` under `tests/fixtures/` causes exit 1 with its path in stderr.
- [ ] Hermetic fixture, path check: a `.py` containing `/Users/someone/data` and a `.py`
      containing `C:\data` each cause exit 1 with the path named in stderr.
- [ ] The cleaned fixture exits 0 (small CSV under the allowed dir, a data file at exactly
      `DS_DATA_MAX_BYTES`, and `.py` files free of absolute paths).
- [ ] Knobs disable independently: `DS_PATH_SCAN=""` makes the hardcoded-path fixture exit
      0 while the oversized-artifact fixture still exits 1, and `DS_DATA_MAX_BYTES=""` the
      converse.
- [ ] With the fixture's only oversized file deleted from the working tree but still
      tracked, the hook exits 0 and prints nothing to stderr. Emptiness is not assertable
      with `check_exit` either — use an inline
      `check "$desc" bash -c '[ -z "$(bash hook 2>&1 >/dev/null)" ]'`.
- [ ] `DS_DATA_ALLOW_DIRS` is honoured as a genuine list: one fixture case sets it to
      `tests/fixtures:data/samples` and an oversized file under each prefix is exempt.
- [ ] `profiles/machine-learning.md` names the hook, its copy-in path, and `REPO_HYGIENE`;
      `profiles/work.md` points at both ML sections and states that only one profile loads.
- [ ] `bash scripts/gate.sh` exits 0; the check count in `ARCHI.md → Verification` matches
      the suite's actual count.

## Deferred

Not scope for this unit; revisit once a real repo has run the hook for a while and there
is evidence to set thresholds against:

- **Secret scanning** — `AKIA…`, `sk-…`, `token = "…"`. The last pattern false-positives
  on `token = "Bearer {}".format(x)`; needs either a suppression mechanism or a measured
  false-positive rate before it earns a place in a blocking gate.
- **Python file-length cap** — 500 lines was a guess with nothing behind it.
- **`scripts/` manifest requirement** — every script named in `scripts/README.md`. Worth
  noting honestly why this is weaker than it first appears: the cheapest way to pass it is
  appending a line without reading the file, so it gates the artifact rather than the
  deliberation. Its real value is making sprawl visible in the review diff, and that value
  decays once the manifest outgrows one screen.

## Release

Release note: Added an opt-in `ds-hygiene.sh` gate hook flagging committed data/model
artifacts and hardcoded local paths, and wired the machine-learning and work profiles to it.

## Verification

- `bash scripts/gate.sh`
- `bash tests/test-scripts.sh`

## Review

Reviewer: `plan-reviewer` (opus, fresh thread) — **REVISE** on draft 1, **REVISE** on
draft 2; all findings from both rounds applied. No unresolved disagreements.

### Round 1 (draft 1)
1. Config block used plain assignment, which clobbers env vars and would have broken the
   plan's own verification commands — now a `: "${VAR=default}"` default, with the
   env-override contract stated. (The exact form was corrected again in round 2.)
2. Check 2 had no disable toggle despite the "empty it to disable" contract — added
   `DS_PATH_SCAN`. The vague "two universal / three opinionated" framing is gone with the
   scope cut.
3. Draft claimed the hook must exclude itself from the path/secret scans; false, since
   those scan `*.py`/`*.ipynb` and the hook is `*.sh`. Removed, along with the vacuous
   "exits 0 against this repo's own tree" criterion it supported.
4. "Names the offending path" was not checkable: `check`/`check_fails` discard both
   streams and `check_exit` greps stderr only. Resolved by specifying stderr diagnostics.
5. Draft over-claimed that the manifest check "forces the author to open a one-screen
   list"; the cheapest passing action is appending a line unread. Claim corrected and
   recorded under `## Deferred`.
6. `\s` is not POSIX and fails on stock BSD grep — now `[[:space:]]`.
7. ARCHI footprint under-specified at two edits; enumerated as four.

Scope: the reviewer's "simpler version" (ship checks 1–2, defer 3–5) was put to the Owner
and **accepted** on 2026-08-27. Consistent with the 2026-08-27 `work/loop-hardening`
retro lesson that a reviewer's "drop this marginal fix" is a cost signal.

### Round 2 (draft 2)

1. **Blocking, self-corrected by the reviewer:** round 1 prescribed `: "${VAR:=default}"`
   and draft 2 adopted it literally, but `:=` substitutes on unset *or null* — an emptied
   knob refills with its default, so criteria 1 and 5 could not both pass. Now the
   colon-less `: "${VAR=default}"`, with the reason stated inline.
2. `DS_DATA_ALLOW_DIRS=""` was an unaddressed third disable path, and the obvious
   `case "$path" in "$prefix"*)` matches every path on an empty prefix — inverting the
   knob into "allow everything". Semantics now stated (empty = no allowed dirs), the
   empty-prefix skip is required of the implementation, and a criterion covers it.
3. "The allowed `.csv` does not appear in the output" is an absence assertion, which no
   existing helper provides. Split into its own criterion naming the inline mechanism, and
   the "no new helper" claim narrowed to the remaining cases.
4. "Does not error the hook" stated no observable — now exit 0 with empty stderr.
5. Working-tree size means the hook goes quiet once an already-committed blob is
   `git rm`ed — the Goal's own history-bloat case. Recorded as an accepted trade, with a
   constraint on what the profile prose may promise.

### Notes for the implementer (round 3, non-blocking)

- **Skip the artifact check before any arithmetic.** With `DS_DATA_MAX_BYTES=""` the
  disable branch must return *before* any `-gt` or `(( ))` — an empty operand is a runtime
  error under `set -u`, and the failure would read as the check firing rather than being
  disabled. This is the likeliest way the implementation trips; criterion 7 catches it.
- The two emptiness/absence assertions (criteria 3 and 8) are the only places needing
  inline `bash -c` rather than the standard helpers.

Plan verdict: APPROVE
