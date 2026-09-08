# Implementer notes — review-diff-base-origin-main

Committed `5701c47 Base codex review diff on origin main`.

- `scripts/codex-review.sh`: best-effort `git fetch origin`, base = `origin/main` when the ref exists else local `main`; diff + DIFF header use the chosen base. Config read (`git show "main:config.yaml"`) unchanged.
- `skills/3-review/SKILL.md` step 1: fetch + `origin/main...wt/<slug>` diff prose.
- `tests/test-scripts.sh`: updated the SKILL.md string assertion; added hermetic cases — stale-local-main pollution excluded (bare remote ahead), and no-remote fallback to local main.

Left unchanged as required: `git show "main:config.yaml"` read, `scripts/release.sh`, fan-exec `main...wt/demo`.

Verification (implementer): `bash tests/test-scripts.sh` → 185 checks passed; `bash scripts/gate.sh` → GATE: PASS.
