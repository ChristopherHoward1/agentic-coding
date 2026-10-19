# Code review round 1 (Claude code-reviewer): APPROVE

Ran: gate (227/0, export 12/0), demo (matches Expected), archi-fresh (0), dispatcher listing, prose greps, footprint, and six mutations in copies.

- MEDIUM 1: `register --subdir ./app` → `/./app/CLAUDE.local.md` exclude line, untracked file. → followup-1 (codex rated it HIGH).
- MEDIUM 2: the state-dir gate hook isn't proven to run; the hook_dir revert mutation survives. → followup-1.
- LOW 3: `harness project mode extra` exits 2 with no message. Recorded, not acted on.
- LOW 4: duplicated lib-copy lines in the release and fan fixtures. → followup-1.
- LOW 5: redundant `dispatch|adopt` guard in fan-exec. Recorded, not acted on.
- LOW 6: three tests prove less than their criteria say:
  - codex marker with no canned reviewer;
  - an untracked decoy;
  - a lookup check run before the config commit.

  Recorded, not acted on.
- LOW 7: the `3-review` step-1 deferrals path lacks the `harness project` prefix. → followup-1.
- LOW 8: the registry `review=approve` condition in `state.sh` has no test. Recorded, not acted on.
