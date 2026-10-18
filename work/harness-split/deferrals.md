# Deferrals — harness-split

- **`template/ARCHI.md:23` names `scripts/gate.sh`** (code-review round 2, LOW). It works through the bootstrap forwarder today. `template/` was off-limits in this unit. It lands in `harness-install`, which deletes the forwarders: fix the skeleton there, or confirm that `harness-publish` has already replaced `template/`.
- **README Getting started uses `ln -s`, not `ln -sf`** (code-review round 2, LOW). A re-run fails with "File exists". It lands in `harness-install`, which replaces the install step.
