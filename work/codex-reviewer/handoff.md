You are the implementer for this work unit. Read AGENTS.md in the repo root first — it is your contract.

Work unit: work/codex-reviewer/plan.md  (read it in full; it is your source of truth — including the Review section's round-5 implementation notes)
Branch: wt/codex-reviewer (already checked out in this worktree — verify with `git branch --show-current` before changing anything)

Footprint (from the plan, repeated here as the hard boundary):
- scripts/codex-review.sh (new)
- scripts/release.sh (second verdict sentinel in check_verdict)
- config.yaml (new `reviewer:` block: command)
- skills/3-review/SKILL.md (dual-reviewer steps, single-commit sentinel recording, stale-line fix)
- tests/test-scripts.sh (hermetic cases, check_exit helper, fixture second-verdict param)
- README.md (loop-diagram edge)

Key constraints:
- `scripts/codex-review.sh <slug>` is a PURE READER run from the primary checkout: it never cd's, and reads BOTH the plan body and config.yaml from the branch via `git show wt/<slug>:...`. Its only write is `$(git rev-parse --show-toplevel)/work/<slug>/codex-review.md` (stdout of the reviewer only; stderr passes through).
- Verdict contract: last line matching `^[[:space:]]*Codex verdict:` (whitespace-tolerant), trimmed, exact-compared. APPROVE → exit 0; REQUEST CHANGES → exit 1; missing/malformed verdict → exit 2; reviewer.command unresolvable → exit 2. Each exit-2 cause gets a distinct stderr message. Optional per plan: `git rev-parse --verify wt/<slug>` precheck for an honest error on a missing branch.
- The awk that reads reviewer.command must anchor the key (`/^[[:space:]]*command:/`, reject leading `#`) and terminate at the next top-level key (`f && /^[^[:space:]#]/ {exit}`). Do NOT copy agent-exec.sh's parser as-is — it has a known lookahead bug. Do NOT modify agent-exec.sh.
- config.yaml `reviewer:` block: `command: 'codex exec --sandbox read-only -'`; no commented-out `command:` alternatives inside the block.
- release.sh check_verdict: add `grep -qx 'Codex-review verdict: APPROVE'` with its own distinct die message. Nothing else in release.sh changes.
- The script never writes verdict sentinels — the orchestrator records both sentinels (Claude + codex) in a single commit on the worktree plan. Your skills/3-review/SKILL.md edit must state these mechanics explicitly (worktree plan, single commit, `git -C <worktree>`, never a whole-file copy from the primary, and the same commit syncs the current plan body onto the branch). Also fix the stale line claiming "/4-release stops for the Owner's push confirmation" — full TRIP now, no push confirmation.
- tests/test-scripts.sh: add a `check_exit <n>` helper that asserts a specific exit code AND a stderr substring. Hermetic cases with a canned reviewer command (override reviewer.command in a fixture config on a fixture branch — tests must not invoke real codex): approve → 0; indented `  Codex verdict: APPROVE` → 0; request-changes → 1; missing verdict → 2 ("no verdict"); reviewer.command absent from branch config → 2 ("reviewer.command"); absent but later block has `command:` → still 2 (parser termination); commented `# command:` above the real one → real one wins; after a canned run `git status --porcelain` shows only the artifact and `git -C <worktree> status --porcelain` is empty. For the release fixture: `setup_release_fixture` gains a second verdict param — appended and defaulted (`${6:-...}`) is fine so existing call sites stay untouched; add the case where Claude sentinel present + codex sentinel absent → release refuses with the new message; ensure the other release cases pass with both sentinels.
- README.md: the mermaid loop diagram's review edge gains the codex verdict (both verdicts shown on the CRev → Rel path).
- Shell style: `set -uo pipefail`, must pass shellcheck (the gate runs it).

When done:
1. Run scripts/gate.sh from the repo root — it must pass.
2. Commit your work on this branch with a clear message.
3. Print a final summary: what changed and why, criteria partially met (if any), out-of-scope observations.
