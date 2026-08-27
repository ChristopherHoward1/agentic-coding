# Which copy of release.sh runs — and when new release machinery binds

`/4-release` runs `bash scripts/release.sh <slug>` **from the primary checkout**, so the *primary's* (= last released) script executes, even though it `cd`s into the release worktree to read the branch's plan, VERSION, and tree.

Consequence: any release-machinery change shipping in unit N (a new precondition, a marker write, a sentinel requirement) does **not** govern unit N's own release. It first *runs* during unit N+1's release, and a precondition that depends on state the script itself writes (e.g. `check_previous_retro` reading `work/.last-released`) first *refuses* anything at unit N+2's release.

Observed twice on 2026-08-26: the dual-sentinel `check_verdict` (v2026.8.6) could not bind its own release, and v2026.8.7's release wrote no `.last-released` marker because the pre-marker script ran. Neither is a bug — write the honesty note in the plan's Release section instead of re-deriving this.

## The codex reviewer has the same shape (v2026.8.8)

`scripts/codex-review.sh` reads `reviewer.command` from **`main:config.yaml`** (`git show main:config.yaml`), not the branch's. Two consequences of the same family: a unit that changes the `reviewer:` block does not govern its own review — the change binds at the next unit's review; and because the ref is the *local* `main`, a stale primary checkout silently runs an older reviewer binary. Keep `main` current before `/3-review`. (Branch-sourcing was the pre-v2026.8.8 behavior and was the vulnerability: branch content could choose the reviewer binary.)
