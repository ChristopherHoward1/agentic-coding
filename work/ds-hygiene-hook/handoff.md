You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/ds-hygiene-hook/plan.md  (read it in full; it is your source of truth)
Branch: wt/ds-hygiene-hook (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/gate.d/examples/ds-hygiene.sh   (new)
- tests/test-scripts.sh                   (add a hermetic fixture + cases, placed after the existing nb-clean block near line 705)
- profiles/machine-learning.md            (new REPO_HYGIENE declaration alongside the existing eval slots)
- profiles/work.md                        (short section pointing at the ML profile's NOTEBOOK_STRATEGY + REPO_HYGIENE)
- ARCHI.md                                (four edits — see constraints)

Do NOT touch:
- scripts/gate.d/ proper — the hook ships as an example and is never auto-enabled in this repo.
- scripts/gate.sh — hook discovery already works.
- config.yaml — no new knob; policy lives in the copied hook.

Key constraints:

1. Model the hook on scripts/gate.d/examples/nb-clean.sh: `set -uo pipefail`, `cd "$(git rev-parse --show-toplevel)" || exit 1`, source truth from `git ls-files`, exit 1 on violation. It must pass shellcheck (the gate enforces this, and examples/ IS shellchecked even though gate.sh's `for hook in scripts/gate.d/*.sh` loop does not reach it).

2. Diagnostics go to STDERR, not stdout. nb-clean.sh prints to stdout, but tests/test-scripts.sh lines 6-21 show `check`/`check_fails` discard both streams and only `check_exit` greps — and it greps stderr. Writing to stderr lets the tests assert the offending path via `check_exit "$desc" 1 "path/to/file" ...` with no new helper.

3. Knobs use the COLON-LESS default form. This is load-bearing and was the subject of a blocking plan-review finding:

       : "${DS_DATA_MAX_BYTES=1048576}"
       : "${DS_DATA_ALLOW_DIRS=tests/fixtures}"   # colon-separated path prefixes
       : "${DS_PATH_SCAN=1}"

   `:=` substitutes when a variable is unset OR null, so an emptied knob would be silently refilled with its default and could never disable anything. `=` substitutes only when unset. Do not use plain `VAR=value` either — it clobbers the environment and breaks the tests and any CI override.

4. Emptying a knob disables its check (`DS_DATA_MAX_BYTES=""`, `DS_PATH_SCAN=""`). CRITICAL: return from the artifact check BEFORE any `-gt` or `(( ))` when DS_DATA_MAX_BYTES is empty — an empty operand is a runtime error under `set -u`, and the failure would read as the check firing rather than being disabled. This is the likeliest way this implementation trips.

5. `DS_DATA_ALLOW_DIRS=""` does NOT follow that pattern. It means NO allowed directories (check everything). The naive `case "$path" in "$prefix"*)` matches EVERY path when the prefix is empty, which would invert the knob into "allow everything" — the implementation must skip empty prefixes. It is a genuine colon-separated list; a value like `tests/fixtures:data/samples` must exempt both prefixes.

6. Check 1 — data/model artifacts: tracked files matching `*.csv *.tsv *.parquet *.pkl *.pickle *.h5 *.hdf5 *.onnx *.joblib *.npy *.npz` whose WORKING-TREE size exceeds DS_DATA_MAX_BYTES and whose path does not start with an allowed prefix. Working-tree size (not blob size) is deliberate: it flags the file before the commit makes it permanent. A tracked path missing from the working tree is SKIPPED, not an error.

7. Check 2 — hardcoded local paths: `/Users/`, `/home/`, `C:\` in tracked `*.py` and `*.ipynb` ONLY. Do not broaden to `*.sh`/`*.md` — that would flag this repo's own profile prose and work-unit plans. Use POSIX character classes (`[[:space:]]`), never `\s`: `\s` is a GNU/ugrep extension that stock BSD `grep -E` on macOS does not honour, and ARCHI commits the stack to macOS/Linux.

8. Tests: build a hermetic fixture repo under $TMP following the nb-clean pattern at tests/test-scripts.sh:658-708 (git init, config user, copy the hook in, commit fixtures). Cover all ten acceptance criteria in the plan. Two of them need inline `bash -c` assertions rather than the standard helpers, because `check_exit` asserts substring PRESENCE only and cannot assert absence or emptiness:
   - allow-dir exemption: `out=$(bash hook 2>&1); ! grep -q allowed.csv <<<"$out"`
   - deleted-but-tracked: `[ -z "$(bash hook 2>&1 >/dev/null)" ]`
   Keep fixture files tiny by lowering DS_DATA_MAX_BYTES from the environment rather than committing a real 1MB blob.

9. Profiles: `machine-learning.md` gains a REPO_HYGIENE declaration naming the hook, its copy-in path (`scripts/gate.d/ds-hygiene.sh`), and the knobs a repo must decide. `work.md` gains a short section pointing at the ML profile's NOTEBOOK_STRATEGY and REPO_HYGIENE — this is an ADDITION, not a de-duplication (work.md has no notebook-hygiene prose today; its only notebook mention is the Snowflake skeleton). The pointer is necessary because config.yaml selects exactly one profile with no merging. Both profiles must state that gate.d/ hooks run on every gate regardless of `profile:`.
   The profile prose must NOT promise recovery of already-committed artifacts: because the hook measures working-tree size, it goes quiet once someone `git rm`s an already-committed blob. That is the accepted trade for a pre-commit gate — say so honestly.

10. ARCHI.md needs FOUR edits (release.sh check_archi_fresh at line 118 compares ARCHI's last commit against `scripts/ skills/ profiles/ config.yaml CLAUDE.md`, so a stale ARCHI blocks the release):
   - the `gate.d/examples/` sentence, which currently names only nb-clean.sh
   - the `profiles/` summary line describing the ML profile's contents
   - the `tests/test-scripts.sh` inventory sentence
   - the `76 checks` count under Verification — set it to the suite's ACTUAL new count, verified by running it

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
