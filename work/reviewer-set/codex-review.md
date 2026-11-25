- **HIGH — Registry state can advance past release based on unrelated repo files.** In `harness/scripts/state.sh:59`, registry mode still reads `work/.last-released` from the Git root. If a registered repository has a marker matching the current slug, an approved registry unit reports `/5-retro` instead of `/4-release`; if `work/<slug>/retro.md` also exists there, it reports `done`. This can happen when registering a repository that previously used repo mode, and contradicts the plan’s rule that registry units remain at release until `pr-release` defines done. Exclude registry mode from the marker and retro checks, and add a registry test with matching repo-side files.

I reviewed the supplied diff and surrounding code. I did not run the gate or mutation tests in the read-only environment.

Codex verdict: REQUEST CHANGES
