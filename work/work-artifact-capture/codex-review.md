Findings:

- `scripts/worktree.sh:57-59`: `[[ -f "$src" ]]` follows symlinks, so a non-dot symlink in `work/<slug>/` pointing at a regular file is copied and committed as file contents. The plan says “top-level regular non-dot files only”; symlinks are not regular files in that sense, and this can accidentally capture arbitrary target contents. Add an explicit `! -L "$src"` guard or use a `find -type f` shape, with a test.

- `skills/2-implement/SKILL.md:21` and `skills/2-implement/SKILL.md:31-38`: the new sync call only covers the initial single-agent dispatch. Followup redispatches and fan-mode adoption do not run `sync-artifacts`, so units escalated before approval/release can still lose the exact artifacts the plan calls out as worth preserving: followups, refreshed notes, and for fan mode even the initial handoff. The prose should put the sync in every dispatch/followup path, including fan-mode convergence or failed fan followup escalation.

Codex verdict: REQUEST CHANGES
