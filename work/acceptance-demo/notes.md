Implemented within the eight-file footprint: demo runner, 15 hermetic checks, prompt/reviewer wiring, and ARCHI documentation.

Validation: `scripts/gate.sh` passed — **200 checks, 0 failures**. Shellcheck and diff checks passed.

Completion is blocked: Git staging cannot write the index outside the sandbox. No commit was created, so the required clean-tree demo was not run; no demo output is available.

Pending: commit, post-commit demo, architecture freshness check, and reviewer mutation evidence. No out-of-scope files changed.

## Orchestrator note

Codex sandbox could not write the worktree git index; orchestrator committed `bec8152` after an independent gate pass (200/200), then ran the demo on the clean tree:

```
demo: no ## Demonstration section
legacy exit=2
<tmpdir>
demo-ran
pass-case exit=0
about-to-fail
demo: block exited with code 3
fail-case exit=1
demo exit=0
```
