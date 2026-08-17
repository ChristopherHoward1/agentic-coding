#!/usr/bin/env bash
# Smoke tests for the deterministic layer. Run from repo root: bash tests/test-scripts.sh
set -uo pipefail

pass=0; fail=0
check() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "ok: $desc"; pass=$((pass+1))
  else
    echo "FAIL: $desc"; fail=$((fail+1))
  fi
}
check_fails() {
  local desc="$1"; shift
  if "$@" >/dev/null 2>&1; then
    echo "FAIL: $desc (expected non-zero exit)"; fail=$((fail+1))
  else
    echo "ok: $desc"; pass=$((pass+1))
  fi
}

ROOT=$(git rev-parse --show-toplevel)
cd "$ROOT" || exit 1

commit_fixture() {
  local repo="$1"
  local stamp="$2"
  local msg="$3"

  (
    cd "$repo" || exit 1
    git add -A
    GIT_AUTHOR_DATE="$stamp" GIT_COMMITTER_DATE="$stamp" git commit -qm "$msg"
  )
}

write_release_fixture_date() {
  local bin_dir="$1"
  local ym="$2"
  local ymd="$3"

  mkdir -p "$bin_dir"
  cat >"$bin_dir/date" <<EOF
#!/usr/bin/env bash
case "\${1:-}" in
  +%Y.%-m) printf '%s\n' "$ym" ;;
  +%F) printf '%s\n' "$ymd" ;;
  *) /bin/date "\$@" ;;
esac
EOF
  chmod +x "$bin_dir/date"
}

setup_release_fixture() {
  local name="$1"
  local version="$2"
  local verdict_line="$3"
  local gate_mode="$4"
  local archi_mode="$5"
  local tmp_root="$TMP/$name"

  REL_PRIMARY="$tmp_root/primary"
  REL_WORKTREE="$tmp_root/demo-wt"
  REL_REMOTE="$tmp_root/remote.git"
  REL_FAKEBIN="$tmp_root/bin"

  mkdir -p "$tmp_root"
  git init -q -b main "$REL_PRIMARY"
  git init -q --bare "$REL_REMOTE"
  (
    cd "$REL_PRIMARY" || exit 1
    git config user.email tester@example.com
    git config user.name Tester
    git remote add origin "$REL_REMOTE"

    mkdir -p scripts skills/3-review skills/1-plan/prompts work/demo
    cp "$ROOT/scripts/release.sh" scripts/release.sh
    cat >scripts/gate.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
if [[ -f GATE_FAIL ]]; then
  echo "GATE: FAIL"
  exit 1
fi
echo "GATE: PASS"
EOF
    chmod +x scripts/release.sh scripts/gate.sh
    printf 'name: fixture\n' >config.yaml
    printf 'merge rules\n' >CLAUDE.md
    printf '%s\n' "$version" >VERSION
    printf '# Changelog\n\nAll notable changes to this project are documented in this file.\n\n' >CHANGELOG.md
    {
      printf '# Demo\n\n'
      printf '## Release\n\n'
      printf 'Release note: Demo release note.\n\n'
      printf '## Review\n\n'
      printf '%s\n' "$verdict_line"
    } >work/demo/plan.md
    [[ "$gate_mode" == fail ]] && printf 'fail\n' >GATE_FAIL
  )
  commit_fixture "$REL_PRIMARY" "2026-08-16T10:00:00Z" source
  printf 'architecture\n' >"$REL_PRIMARY/ARCHI.md"
  commit_fixture "$REL_PRIMARY" "2026-08-16T10:01:00Z" archi
  if [[ "$archi_mode" == stale ]]; then
    printf 'merge rules updated\n' >>"$REL_PRIMARY/CLAUDE.md"
    commit_fixture "$REL_PRIMARY" "2026-08-16T10:02:00Z" stale-source
  fi
  (
    cd "$REL_PRIMARY" || exit 1
    git push -q -u origin main
    git branch wt/demo
    git worktree add -q "$REL_WORKTREE" wt/demo
    git -C "$REL_WORKTREE" config user.email tester@example.com
    git -C "$REL_WORKTREE" config user.name Tester
  )
  write_release_fixture_date "$REL_FAKEBIN" "2026.8" "2026-08-16"
}

# --- shellcheck the scripts themselves (gate.sh covers this too; belt+braces)
if command -v shellcheck >/dev/null; then
  check "shellcheck scripts" shellcheck scripts/*.sh tests/*.sh
fi

# --- worktree.sh lifecycle in a throwaway repo
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
(
  cd "$TMP"
  git init -q -b main sandbox && cd sandbox
  git commit -q --allow-empty -m init
  cp "$ROOT/scripts/worktree.sh" wt.sh
  printf 'worktrees:\n  dir: ../wts\n' > config.yaml
  git add -A && git commit -qm files
) || { echo "FAIL: sandbox setup"; exit 1; }

SB="$TMP/sandbox"
WT_PATH=$(cd "$SB" && bash wt.sh add demo 2>/dev/null)
check "worktree add creates directory" test -d "$WT_PATH"
check "worktree branch checked out" bash -c "cd '$WT_PATH' && [ \"\$(git branch --show-current)\" = wt/demo ]"
check "worktree.sh works FROM INSIDE a worktree (.git-as-file)" bash -c "cd '$WT_PATH' && bash wt.sh list"
check "worktree remove" bash -c "cd '$SB' && bash wt.sh remove demo"
check_fails "worktree add without slug fails" bash -c "cd '$SB' && bash wt.sh add"

# --- agent-exec.sh argument validation
check_fails "agent-exec rejects missing handoff" bash scripts/agent-exec.sh /tmp nonexistent-handoff.md

# --- release.sh version comparison
check "release version compare accepts .10 over .9" bash scripts/release.sh check-version 2026.8.10 2026.8.9
check_fails "release version compare rejects .9 after .10" bash scripts/release.sh check-version 2026.8.9 2026.8.10

# --- release.sh refusals and happy path in the mandated worktree topology
setup_release_fixture release-no-verdict 2026.8.9 "Plan verdict: APPROVE" pass fresh
check_fails "release refuses without code-review approval" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-gate-fails 2026.8.9 "Code-review verdict: APPROVE" fail fresh
check_fails "release refuses when gate fails" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-archi-stale 2026.8.9 "Code-review verdict: APPROVE" pass stale
check_fails "release refuses when ARCHI.md is stale" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-version-regresses 2026.9.0 "Code-review verdict: APPROVE" pass fresh
check_fails "release refuses when computed version does not exceed VERSION" bash -c "cd '$REL_WORKTREE' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo"

setup_release_fixture release-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
check "release happy path lands fast-forward on primary main and stops before push" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
  [ \"\$(git -C '$REL_PRIMARY' branch --show-current)\" = main ] &&
  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.10 ] &&
  git -C '$REL_PRIMARY' merge-base --is-ancestor wt/demo main &&
  git -C '$REL_PRIMARY' rev-parse --verify --quiet refs/tags/v2026.8.10 &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ]
"

setup_release_fixture release-tag-race-rolls-back 2026.8.9 "Code-review verdict: APPROVE" pass fresh
release_head_before=$(git -C "$REL_WORKTREE" rev-parse HEAD)
real_git=$(command -v git)
tag_fail_bin="$TMP/tag-fail-bin"
mkdir -p "$tag_fail_bin"
cat >"$tag_fail_bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == tag && "\${2:-}" == v2026.8.10 ]]; then
  "$real_git" tag v2026.8.10 HEAD~1
fi
"$real_git" "\$@"
EOF
chmod +x "$tag_fail_bin/git"
check "release rolls back cleanly when tag creation fails after prechecks" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$tag_fail_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >/dev/null 2>&1 &&
  exit 1
  status=\$?
  [ \"\$status\" -ne 0 ] &&
  [ \"\$(git rev-parse HEAD)\" = '$release_head_before' ] &&
  [ \"\$(cat VERSION)\" = 2026.8.9 ] &&
  git diff --quiet &&
  git diff --cached --quiet &&
  [ -z \"\$(git ls-files --others --exclude-standard)\" ] &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
"

setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
check "release can be invoked from primary checkout" bash -c "cd '$REL_PRIMARY' && PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo && [ \"\$(cat VERSION)\" = 2026.8.10 ]"

# --- gate.sh runs and exits cleanly on this repo
check "gate.sh runs on this repo" bash scripts/gate.sh

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"
