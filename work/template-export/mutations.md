# Mutation checks

Each mutation was checked byte-for-byte before running the suite; the original script was restored afterward.

- argument-count: mutation verified; suite exit 1; FAIL: no arguments refuses with usage; FAIL: extra arguments refuses with usage and writes nothing
- nonempty-destination: mutation verified; suite exit 1; FAIL: non-empty destination refuses without writes
- file-destination: mutation verified; suite exit 1; FAIL: file destination refuses without writes
- base-HEAD: mutation verified; suite exit 1; FAIL: base and overlay both reflect HEAD
- overlay-HEAD: mutation verified; suite exit 1; FAIL: base and overlay both reflect HEAD
- repository-root-cd (review round 1): removed only `cd "$root" || error 'cannot enter repository root'`; verified the mutation byte-for-byte before running `bash tests/test-export.sh`; suite exit 1, passed: 7, failed: 1; FAIL: subdirectory export resolves relative destination against caller cwd. Restored the original script and verified restoration with `cmp`. The case exports from the fixture's `scripts/` directory to relative `out`, checking `scripts/out/CLAUDE.md`, `VERSION=1970.1.0`, and no repo-root `out`.
