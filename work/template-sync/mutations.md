# Guard mutations

Each mutation was applied to the working script, verified by exact text assertions, tested through the fixture’s own copy, then restored.

- remove tag check: landed (old text absent, replacement present); exit 1; FAIL: sync (c): missing release tag refuses; two lightweight tags succeed. Restored.

- describe --exact-match: landed (old text absent, replacement present); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged; FAIL: sync (c): missing release tag refuses; two lightweight tags succeed. Restored.

- remove git rm: landed (old text absent, replacement present); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push. Restored.

- remove no-op cleanup: initial result superseded by the macOS recheck below; bare `mktemp -d` did not put the directories under the test's TMPDIR, so the initial record did not establish cleanup on macOS.

- trap-delete clone: landed (old text absent, replacement present); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged; FAIL: sync (c): missing release tag refuses; two lightweight tags succeed. Restored.
- add git push: landed (push command present, script differs from original); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push. Restored.

## Review round 1 recheck — macOS (Darwin), 2026-10-09

Both sync directories now use `mktemp -d "${TMPDIR:-/tmp}/sync.XXXXXX"`. Each mutation below was applied separately, verified by exact assertions that the original text was absent and the replacement present, and run through `bash tests/test-export.sh` on this machine. The fixture commits the working script and invokes its own copy. All three mutations were restored, with exact equality to the fixed script checked afterwards.

- Replace `grep -Fqx "v$version"` with `grep -qx "v$version"`: landed; exit 1; FAIL: sync (c): missing and near-match release tags refuse; two lightweight tags succeed. The near-match fixture has only `v${version//./x}` on HEAD.
- Remove the no-op `rm -rf "$clone"` command: landed; exit 1; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged. The retained clone is now inside the test's TMPDIR, so the empty-directory assertion detects it.
- Remove `trap 'rm -rf "$exp"' EXIT`: landed; exit 1; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged. The retained export is now inside the test's TMPDIR, so the empty-directory assertion detects it.

The test's outer cleanup removes these fixture directories, including retained mutation artifacts.
