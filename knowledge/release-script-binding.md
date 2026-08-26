# Which copy of release.sh runs — and when new release machinery binds

`/4-release` runs `bash scripts/release.sh <slug>` **from the primary checkout**, so the *primary's* (= last released) script executes, even though it `cd`s into the release worktree to read the branch's plan, VERSION, and tree.

Consequence: any release-machinery change shipping in unit N (a new precondition, a marker write, a sentinel requirement) does **not** govern unit N's own release. It first *runs* during unit N+1's release, and a precondition that depends on state the script itself writes (e.g. `check_previous_retro` reading `work/.last-released`) first *refuses* anything at unit N+2's release.

Observed twice on 2026-08-26: the dual-sentinel `check_verdict` (v2026.8.6) could not bind its own release, and v2026.8.7's release wrote no `.last-released` marker because the pre-marker script ran. Neither is a bug — write the honesty note in the plan's Release section instead of re-deriving this.
