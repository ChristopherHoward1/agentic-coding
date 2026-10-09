1. **MEDIUM — `scripts/export-template.sh:24–25`: export depends on the caller’s directory.** Running `cd scripts && ./export-template.sh /tmp/template` archives only the `scripts/` subtree, while the overlay lookup finds no `template/` files. The script exits 0 with an incomplete template lacking the skeletons and bootstrap VERSION. Normalize to the repository root before the Git commands, as `worktree.sh` does.

ShellCheck and branch freshness passed. The gate could not run: the read-only sandbox denied Bash’s temporary file creation. The demonstration and consumer smoke suite therefore remain independently unverified.

Codex verdict: APPROVE
