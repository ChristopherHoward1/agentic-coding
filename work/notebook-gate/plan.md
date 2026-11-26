# Notebook gate

**Slug:** notebook-gate · **Date:** 2026-11-26 · **Status:** approved

## Goal

At work, most real defects showed up only when notebooks were executed (papermill on GPU), never in static review (Owner's field report, 2026-10-17). Data is gitignored and lives only in the primary checkout, so a unit worktree has no data to run against. The gate has no execution step for notebooks and no check that the data still has the shape the code expects. The roadmap names this unit `notebook-gate` ("papermill + committed data contracts"). The Owner confirmed this reading and the two-part scope on 2026-11-26.

Done = two opt-in example gate hooks, enabled from the `machine-learning` and `work-slim` profiles:
1. **`nb-exec.sh`** runs listed notebooks through papermill in smoke mode, reading data from the primary checkout. It writes outputs only to a temp directory and fails the gate when a notebook raises.
2. **`data-contract.sh`** checks committed contracts against the real data in the primary checkout: columns, dtypes and a row-count range per dataset. Schema drift therefore fails before a notebook runs.

## Approach

Both hooks follow the existing `harness/examples/gate.d/` pattern (`nb-clean.sh`, `ds-hygiene.sh`):
- They are bash files the Owner copies into `scripts/gate.d/`, or the state dir's `scripts/gate.d/` in registry mode.
- Settings are env vars with in-file defaults, so editing the copied file is the configuration.
- They exit 0 to pass or skip and 1 to fail. Diagnostics (every failure and refusal message) go to stderr, which `check_exit` greps (`knowledge/test-helper-contract.md`). Skip and `ok` lines go to stdout. `gate.sh` shows both.

Unlike `nb-clean`, they run from the directory the gate gives them, which is the project root. They never `cd` to the git toplevel, so registry subfolder projects work.

**Data root.** Each hook prints its skip line and exits before it resolves the data root, so an idle hook never fails on a missing primary folder. Both hooks resolve the root the same way: the primary checkout, which is the first `git worktree list --porcelain` entry, plus the cwd's `git rev-parse --show-prefix`. From a unit worktree, this is the primary checkout's copy of the same project folder, which holds the real gitignored data. From the primary checkout it's the cwd. An `NB_DATA_ROOT` override, an absolute path, takes precedence. The root is normalized with `cd -P … && pwd`, as `project.sh` does, so paths compare as real paths on macOS. If that directory doesn't exist in the primary checkout, the hook fails with `<hook>: no <path> in the primary checkout`.

### `nb-exec.sh`

- `NB_EXEC_NOTEBOOKS` is a colon-separated list of notebook paths relative to the project root.
  - Empty, the default: print `nb-exec: no notebooks listed; skipping` and exit 0.
  - A listed notebook that doesn't exist fails with `nb-exec: missing notebook <path>`.
  - A listed notebook with no `parameters`-tagged cell fails with `nb-exec: <nb> has no parameters-tagged cell`, before papermill runs. A grep of the notebook JSON for `"parameters"` is a heuristic: a committed papermill output notebook carries `metadata.papermill.parameters`, which would pass it. Without that cell, papermill injects at the top and the notebook's own assignments override `smoke`, so the gate would do a full run.
- `papermill` must be on `PATH`. The papermill check (`command -v`, a builtin) runs first, before any external tool. Otherwise it fails with `nb-exec: papermill not found`. The profiles also tell the Owner to add `papermill` to `gate.required_tools`.
- Each notebook runs as:
  `papermill <nb> <tmp>/<name> --cwd <notebook's dir> -p data_dir <data-root> -p out_dir <tmp>/out -p smoke 1 --execution-timeout <NB_EXEC_CELL_TIMEOUT>`
  - `--cwd` starts the kernel in the notebook's own directory, as Jupyter does, so sibling imports and relative configs behave as they do for the Owner.
  - `out_dir` is a temp directory for the notebook's own side effects (figures, outputs).
  - The default cell timeout is 600 seconds. It is per cell, which is papermill's own timeout. A whole-notebook timeout would need GNU `timeout`, which macOS lacks.
  - Optional `NB_EXEC_KERNEL` adds `-k <kernel>`.
  - `<tmp>` is one `mktemp -d` per notebook, outside the repo. Notebooks with the same basename don't collide, and removing a passing notebook's output never touches a kept failure.
- **On success:** remove the temp output and print `nb-exec: ok <nb>`.
- **On failure:** print `nb-exec: FAILED <nb>`, the last 20 lines of papermill's stderr and the kept output path. Then continue to the next notebook and exit 1 at the end.
- The hook writes nothing under the repo. A notebook that writes relative to its cwd still writes into the worktree; the hook can't prevent that, so the profile's notebook contract forbids it.
- The notebook contract goes in the profile prose:
  - a `parameters`-tagged cell declares `data_dir`, `out_dir` and `smoke`;
  - `smoke` cuts the work down to a quick slice;
  - side effects go under `out_dir`, never relative to the cwd.

### `data-contract.sh`

- `DATA_CONTRACT_DIR` is `contracts` by default, relative to the project root.
  - No directory, or no `*.json` files in it: print `data-contract: no contracts; skipping` and exit 0.
- Contracts are JSON, because `python3` reads JSON with the stdlib and needs no PyYAML. A contract per dataset `contracts/<name>.json` looks like:
  `{"path": "data/sales.csv", "columns": {"id": "int", "amount": "float", "region": "str"}, "rows": [100, null], "extra_columns": "forbid"}`
  - `path` is relative to the data root.
  - `rows` is `[min, max]` over data rows (a CSV header is not counted), where `max: null` means no upper bound.
  - `extra_columns` is `forbid` (the default) or `allow`.
  - Dtypes are `int`, `float`, `str`, `bool` and `any`. `any` checks presence only, for date and timestamp columns.
- The check is a `python3 -I` script embedded in the hook. Per contract it fails with a named message when any of these happens:
  - `missing data file <abs path> (data lives in the primary checkout)`;
  - a missing column;
  - an extra column under `forbid`;
  - a dtype mismatch, naming the column, the expected dtype and the first offending value or the actual type;
  - a row count outside the range;
  - a malformed contract (`bad contract <file>: ...`).

  It reports every failure across all contracts, then exits 1.
- **Formats:**
  - **`.csv`** uses the stdlib `csv` module. The row count is always exact. The file is opened with `open(path, newline='', encoding='utf-8-sig')`, so an Excel BOM doesn't rename the first column. The dtype scan covers the first `DATA_CONTRACT_SCAN_ROWS` data rows (default 100000). The row count still reads the whole file, so the cap only saves per-value parsing on a large CSV. Every non-empty value scanned must parse as the dtype: `int()`; `float()`; any value for `str`; `true`/`false`/`0`/`1`, case-insensitive, for `bool`.
  - **`.parquet`** needs `pyarrow`. If the import fails: `data-contract: <file>: parquet needs pyarrow`. Arrow types map as `int*`/`uint*`→`int`, `float*`/`double`/`decimal`→`float`, `string`/`large_string`→`str`, `bool`→`bool`. Rows come from metadata, so the data is not loaded.
  - Any other extension fails with `unsupported format`.

### Profiles

- **`machine-learning.md`** rewords NOTEBOOK_STRATEGY: notebooks are exploratory by default, and those listed under NOTEBOOK_EXEC are gated in smoke mode. It also gets two declarations next to `REPO_HYGIENE`:
  - **NOTEBOOK_EXEC:** which notebooks to list and the `data_dir`/`smoke` parameter contract;
  - **DATA_CONTRACTS:** which datasets get contracts.

  Each says to copy the hook from `$(harness root)/examples/gate.d/`.
- **`work-slim.md`'s** declarations line gains both, with `papermill` in `gate.required_tools` for the execution hook.
- **`work.md`:**
  - line 22's copy list gains `NOTEBOOK_EXEC` and `DATA_CONTRACTS`;
  - line 63 gains "the `nb-exec` and `data-contract` hooks run from the project root".

### Prose

- **`ARCHI.md`:** the `harness/examples/gate.d/` mention and the test-scripts and gate summaries.
- **`README.md`:** unchanged. Its Layout line only says "opt-in gate hooks".

### Not covered

- **GPU-sized runs.** The gate runs smoke mode only. Full runs stay at review time, as `machine-learning.md` already says for expensive evals.
- **Contract generation from data.** Contracts are written by hand. A generator is a later unit if hand-writing them becomes friction.
- **Datetime dtype checks.** `any` covers presence only.
- **Unmapped Arrow types**, such as `dictionary<…>` from pandas `category` columns. These need `any`.
- **Partitioned Parquet directories** (e.g. `raw/snowflake/dt=…/`). A directory `path` fails with `unsupported format`, so a contract names one file.
- **A gate-level fixture.** The gate fixtures put only `bash`, `git` and `awk` on `PATH`, but these hooks also need `mktemp`, `tail`, `dirname` and `python3`. Tests call the hooks directly.

## Footprint

Files to modify:
- `harness/examples/gate.d/nb-exec.sh` (new)
- `harness/examples/gate.d/data-contract.sh` (new)
- `harness/tests/test-scripts.sh` (new cases)
- `harness/profiles/machine-learning.md`
- `harness/profiles/work-slim.md`
- `harness/profiles/work.md` (lines 22 and 63)
- `ARCHI.md`
- `PLAN.md` (orchestrator: this unit's Now line and roadmap)

Files NOT to touch:
- `harness/scripts/gate.sh`: hooks already run from the project root and their output is shown.
- `harness/examples/gate.d/nb-clean.sh` and `ds-hygiene.sh`.

## Acceptance criteria

Tests are hermetic and follow `knowledge/test-helper-contract.md`:
- Every assertion is `|| return 1`.
- Descriptions start with `nb-exec` or `data-contract`, so `TEST_FILTER` can select them.
- Failure messages are asserted with `check_exit` (stderr). Skip and `ok` lines are asserted inline: `bash -c 'out=$(hook); grep -q … <<<"$out"'`. `nb-exec` cases use a stub `papermill` on `PATH`. The stub records its argv, writes its output path, and exits 1 when the notebook contains `RAISE`. They run with `TMPDIR="$TMP/nbtmp"`, so kept outputs stay inside the suite's temp dir, and "outside the repo" is asserted as a path under that dir. Cases asserting two substrings use the inline form `bash -c 'err=$(hook 2>&1 >/dev/null); …'`.

**`nb-exec.sh`**
- [ ] **Skips when idle.** No list: exits 0 and prints `no notebooks listed`.
- [ ] **Refuses broken setups.** A listed notebook with no `parameters`-tagged cell exits 1 with `has no parameters-tagged cell`, and papermill is not called (the stub log is empty). Exits 1 with `papermill not found`, using a restricted `PATH` that has the hook's tools (`bash`, `git`, `mktemp`, `tail`, `dirname`) but no papermill. Exits 1 with `missing notebook` for an absent listed path.
- [ ] **Calls papermill correctly.** Run from a linked worktree whose data exists only in the primary checkout, the stub's argv has:
  - `-p data_dir <primary checkout project root>`, an absolute path that is not the worktree;
  - `--cwd <the notebook's directory>`;
  - `-p out_dir <a path outside the repo>`;
  - `-p smoke 1`;
  - `--execution-timeout 600`;
  - and `-k <kernel>` when `NB_EXEC_KERNEL` is set.
- [ ] **`NB_DATA_ROOT` override.** It replaces `data_dir`.
- [ ] **Failure.** Two notebooks, the first raising: the hook exits 1, prints `FAILED <first>` and the kept output path, and still runs the second (the stub log shows both).
- [ ] **Clean tree.** After a passing and a failing run, `git status --porcelain` in the worktree is empty. The output notebook and `out_dir` exist only under the temp dir.
- [ ] **Subfolder.** Run from `<linked worktree>/<subdir>`, the hook resolves `data_dir` to `<primary>/<subdir>`. A subfolder missing from the primary checkout fails with `no … in the primary checkout`.

**`data-contract.sh`**

Fixtures are tiny **untracked** CSVs in the primary checkout, gitignored so that the worktree has no copy, and the hook runs from a linked worktree.
- [ ] **Subfolder and override.** Run from `<linked worktree>/<subdir>`, a contract `path` resolves under `<primary>/<subdir>`. `NB_DATA_ROOT` replaces the data root.
- [ ] **BOM and `any`.** A CSV with a UTF-8 BOM header passes. An `any` column passes with any values, and an `any` column missing from the data fails as a missing column.
- [ ] **Passes.** A CSV matching its contract exits 0. So does a `rows: [n, n]` contract whose CSV has exactly `n` data rows plus a header; the header doesn't count.
- [ ] **Scan cap.** With `DATA_CONTRACT_SCAN_ROWS=2`, a bad value in data row 3 passes the dtype check, while the row count stays exact.
- [ ] **Each named failure.** Each of the following exits 1 with its message:
  - missing column;
  - extra column under `forbid`;
  - `extra_columns: allow` passes;
  - `int` column with `x`;
  - `float` column with `abc`;
  - `bool` column with `maybe`;
  - row count under `min`;
  - row count over `max`;
  - missing data file, with the message containing `primary checkout`;
  - malformed JSON;
  - unsupported extension.
- [ ] **Reports every failure.** Two failing contracts: both are reported, and the exit is 1.
- [ ] **Skips when idle.** No contracts directory: exits 0 and prints `no contracts`.
- [ ] **Parquet without pyarrow.** Forced on every platform: a `python3 -m venv --without-pip "$TMP/nopa"` goes first on `PATH`, which hides pyarrow (`-I` ignores `PYTHONPATH`). The hook exits 1 with `parquet needs pyarrow`.
- [ ] **Parquet with pyarrow.** This runs only when the default `python3` imports pyarrow, which is true locally, and prints that it ran. A matching file whose `int64` column is contracted as `int` passes, and the same column contracted as `str` fails. The `int64`→`float` mutation pin therefore runs locally only.

**Both**
- [ ] **Mutation pins.** Each is shown to fail the suite after confirming it landed:
  - resolve the data root from the cwd, not the primary checkout (once per hook);
  - drop `--show-prefix` from the data root (once per hook);
  - drop the parameters-cell check;
  - drop `-p smoke 1`;
  - write papermill output inside the repo;
  - stop after the first failing notebook;
  - drop the dtype check;
  - drop the row-range check;
  - treat `forbid` as `allow`;
  - stop after the first failing contract;
  - drop the pyarrow import guard;
  - map `int64` to `float`;
  - drop `--cwd`;
  - count the CSV header as a row.
- [ ] **Profile wording.** `grep -n 'NOTEBOOK_EXEC\|DATA_CONTRACTS' harness/profiles/machine-learning.md harness/profiles/work-slim.md harness/profiles/work.md` matches in all three profiles.
- [ ] `harness archi-fresh wt/notebook-gate` exits 0.
- [ ] `harness gate` passes.

## Release

Release note: Two opt-in example gate hooks for data-science repos. `nb-exec.sh` runs listed notebooks through papermill in smoke mode (`-p data_dir <primary checkout> -p smoke 1`) with outputs kept out of the repo. `data-contract.sh` checks committed JSON contracts (columns, dtypes, row range) against the real CSV or Parquet data in the primary checkout. The `machine-learning` and `work-slim` profiles gain `NOTEBOOK_EXEC` and `DATA_CONTRACTS` declarations.

## Demonstration

This runs the branch's hooks on real inputs under `mktemp -d`.
- `data-contract.sh` checks a real CSV and a real Parquet file, using the venv's `pyarrow` (the venv's `python3` is first on `PATH`).
- `nb-exec.sh` runs a real notebook through real papermill, which is installed into a temp venv. That needs network and takes about a minute, so a demo failure at `pip install` is a network problem, not the code.
- The notebook asserts that its cwd is the notebook's directory, and writes a file to `out_dir`.

```sh
HK="$PWD/harness/examples/gate.d"
d=$(mktemp -d)
trap 'rm -rf "$d"' EXIT
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@t GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@t
python3 -m venv "$d/venv"
"$d/venv/bin/pip" install -q papermill ipykernel pyarrow >/dev/null
export PATH="$d/venv/bin:$PATH"
git init -qb main "$d/repo"
cd "$d/repo"
printf 'data/\n' >.gitignore
mkdir -p contracts data nb
printf 'id,amount\n1,2.5\n2,3.0\n' >data/sales.csv
python3 -c 'import pyarrow as pa, pyarrow.parquet as pq; pq.write_table(pa.table({"id":[1,2]}), "data/ids.parquet")'
printf '{"path": "data/sales.csv", "columns": {"id": "int", "amount": "float"}, "rows": [1, null]}\n' >contracts/sales.json
printf '{"path": "data/ids.parquet", "columns": {"id": "int"}, "rows": [2, 2]}\n' >contracts/ids.json
python3 - <<'PY'
import json
cells=[{"cell_type":"code","metadata":{"tags":["parameters"]},"source":"data_dir='.'\nout_dir='.'\nsmoke=0","outputs":[],"execution_count":None},
       {"cell_type":"code","metadata":{},"source":"import csv,os\nrows=list(csv.reader(open(os.path.join(data_dir,'data/sales.csv'))))\nassert int(smoke)==1\nassert os.path.basename(os.getcwd())=='nb'\nos.makedirs(out_dir,exist_ok=True)\nopen(os.path.join(out_dir,'n.txt'),'w').write(str(len(rows)-1))","outputs":[],"execution_count":None}]
meta={"kernelspec":{"name":"python3","display_name":"Python 3","language":"python"}}
json.dump({"cells":cells,"metadata":meta,"nbformat":4,"nbformat_minor":4},open("nb/check.ipynb","w"))
bad=[cells[0],{"cell_type":"code","metadata":{},"source":"raise ValueError('boom')","outputs":[],"execution_count":None}]
json.dump({"cells":bad,"metadata":meta,"nbformat":4,"nbformat_minor":4},open("nb/bad.ipynb","w"))
PY
git add -A
git commit -qm init
git worktree add -q "$d/wt" -b wt/demo
cd "$d/wt"
bash "$HK/data-contract.sh"
echo "contract exit=$?"
NB_EXEC_NOTEBOOKS=nb/check.ipynb bash "$HK/nb-exec.sh"
echo "nb-exec exit=$?"
NB_EXEC_NOTEBOOKS=nb/check.ipynb:nb/bad.ipynb bash "$HK/nb-exec.sh" || echo "nb-exec both exit=$?"
echo "status=[$(git status --porcelain)]"
printf '{"path": "data/sales.csv", "columns": {"id": "int", "amount": "int"}, "rows": [1, null]}\n' >"$d/repo/contracts/sales.json"
cp "$d/repo/contracts/sales.json" contracts/sales.json
bash "$HK/data-contract.sh" || echo "drift exit=$?"
```

The demo runs from a linked worktree that has no `data/` (it's gitignored), so both hooks must read the primary checkout's copy.

Expected:
1. `contract exit=0`.
2. `nb-exec: ok nb/check.ipynb`, then `nb-exec exit=0`. The cwd assertion passed and `out_dir` was written outside the repo.
3. `ok nb/check.ipynb`, then `FAILED nb/bad.ipynb` with a stderr tail containing `ValueError` and `boom` (possibly ANSI-coloured) and a kept path outside the repo, then `nb-exec both exit=1`.
4. `status=[]`: neither hook wrote into the worktree.
5. A dtype failure naming `amount`, `int` and `2.5`, then `drift exit=1`.

## Review

Plan review round 1: REVISE, six findings and four smaller points, all applied:
1. Diagnostics go to stderr, and the plan names the helper per criterion.
2. Papermill gets `--cwd <notebook dir>`, pinned by argv and a mutation.
3. `out_dir` is a parameter; the clean-tree claim is limited to the hook, and the contract forbids relative writes.
4. NOTEBOOK_STRATEGY is reworded, and `work.md` lines 22 and 63 are in the footprint.
5. The no-pyarrow branch is forced with a `--without-pip` venv on every platform, with two parquet mutations.
6. The header is excluded from rows, with an exact-count case; a scan cap was added; partitioned Parquet is out of scope.
7. Smaller points: a restricted `PATH` for the papermill-missing case, `cd -P` normalization, demo wording and a network note, and a demo assertion for cwd and `out_dir`.

Plan review round 2: REVISE, three MEDIUMs and five LOWs, all applied:
1. **Parameters cell (MEDIUM).** The hook refuses a notebook with no `parameters`-tagged cell before calling papermill. A case and a mutation pin this.
2. **Failure path (MEDIUM).** The demo now runs a raising notebook through real papermill, alongside the passing one.
3. **Subfolder data root (MEDIUM).** Subfolder cases run from a linked worktree, for both hooks. Each hook gets its own cwd and show-prefix mutations, and `data-contract` gets an `NB_DATA_ROOT` case.
4. **Smaller fixes (LOWs).**
   - an `any` dtype for date columns;
   - an honest scan-cap rationale;
   - `utf-8-sig` for CSV opening;
   - `TMPDIR` under the suite temp dir;
   - the tool-order statement;
   - an inline form for two-substring cases;
   - a named message when the subfolder is missing from the primary checkout.

Plan review round 3: APPROVE, with ten LOWs. Applied:
- the `work.md` line-63 wording, with `work.md` added to the profile grep;
- papermill is checked first;
- one temp dir per notebook;
- skip before the data root is resolved;
- the passing Parquet fixture's columns are named, and the `int64` pin is local-only;
- untracked fixtures;
- the ANSI-tolerant demo expectation;
- `nbformat_minor` 4;
- the parameters grep is labelled a heuristic;
- unmapped Arrow types need `any`.

Plan verdict: APPROVE

Code review round 1:
- **Codex: REQUEST CHANGES**, one HIGH and one MEDIUM.
  - **HIGH:** the gate keeps running hooks after a failure, so `nb-exec` ran notebooks after a contract had failed.
  - **MEDIUM:** the contract format was undocumented for users.
- **Code-reviewer: APPROVE**, after the 14 mutation pins plus extras each failed the filtered suite. Three MEDIUMs:
  - the `data-contract` override case was vacuous;
  - `out_dir` was unpinned;
  - the pyarrow ran/skipped note was invisible.
- **Followup 1 fixed all of these, plus five LOWs:**
  - `nb-exec` runs a sibling `data-contract.sh` first and skips the notebooks when it fails;
  - the contract format is documented in the hook header and in `DATA_CONTRACTS`;
  - blank CSV lines are skipped;
  - `halffloat` maps to `float`;
  - no double slash in the temp path;
  - idle-skip cases run from a subfolder missing in the primary checkout;
  - the dead test line is removed.
