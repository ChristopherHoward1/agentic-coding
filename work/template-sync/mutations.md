# Guard mutations

Each mutation was applied to the working script, verified by exact text assertions, tested through the fixture’s own copy, then restored.

- remove tag check: landed (old text absent, replacement present); exit 1; FAIL: sync (c): missing release tag refuses; two lightweight tags succeed. Restored.

- describe --exact-match: landed (old text absent, replacement present); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged; FAIL: sync (c): missing release tag refuses; two lightweight tags succeed. Restored.

- remove git rm: landed (old text absent, replacement present); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push. Restored.

- remove no-op cleanup: landed (old text absent, replacement present); exit 1; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged. Restored.

- trap-delete clone: landed (old text absent, replacement present); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push; FAIL: sync (b): up to date leaves TMPDIR empty and refs unchanged; FAIL: sync (c): missing release tag refuses; two lightweight tags succeed. Restored.
- add git push: landed (push command present, script differs from original); exit 1; FAIL: sync (a): exact export tree, preserved parent and clone, no push. Restored.
