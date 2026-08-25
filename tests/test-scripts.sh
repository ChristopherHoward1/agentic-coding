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
if compgen -G "scripts/gate.d/*.sh" >/dev/null; then
  for hook in scripts/gate.d/*.sh; do
    bash "$hook"
  done
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

setup_fan_fixture() {
  local name="$1"
  local pass_mode="${2:-some}"
  local tmp_root="$TMP/$name"

  FAN_PRIMARY="$tmp_root/primary"
  FAN_WTS="$tmp_root/wts"
  FAN_IMPL="$tmp_root/canned-implementer.sh"
  FAN_HANDOFF="$FAN_PRIMARY/work/demo/handoff.md"

  mkdir -p "$tmp_root"
  git init -q -b main "$FAN_PRIMARY"
  (
    cd "$FAN_PRIMARY" || exit 1
    git config user.email tester@example.com
    git config user.name Tester

    mkdir -p scripts work/demo
    cp "$ROOT/scripts/worktree.sh" scripts/worktree.sh
    cp "$ROOT/scripts/agent-exec.sh" scripts/agent-exec.sh
    cp "$ROOT/scripts/fan-exec.sh" scripts/fan-exec.sh
    cat >scripts/gate.sh <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
cd "$(git rev-parse --show-toplevel)" || exit 1
[[ -f result.txt ]] || exit 1
grep -qx pass result.txt
EOF
    chmod +x scripts/*.sh

    cat >"$FAN_IMPL" <<'EOF'
#!/usr/bin/env bash
set -uo pipefail
cat >/dev/null
branch=$(git branch --show-current)
git config user.email tester@example.com
git config user.name Tester
if [[ ! -f work/demo/plan.md ]]; then
  printf 'missing-seed\n' >result.txt
elif [[ "${FAN_PASS_MODE:-some}" == all-fail ]]; then
  printf 'fail\n' >result.txt
elif [[ "$branch" == wt/demo-fan-2 || "$branch" == wt/demo-fan-3 ]]; then
  printf 'pass\n' >result.txt
else
  printf 'fail\n' >result.txt
fi
printf '%s\n' "$branch" >branch.txt
git add result.txt branch.txt work/demo/plan.md
git commit -qm "implement $branch"
EOF
    chmod +x "$FAN_IMPL"

    cat >config.yaml <<EOF
implementer:
  command: 'FAN_PASS_MODE=$pass_mode $FAN_IMPL'
worktrees:
  dir: $FAN_WTS
EOF
    printf '# Demo plan\n' >work/demo/plan.md
    printf 'handoff\n' >work/demo/handoff.md
    git add -A
    git commit -qm init
  )
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

# --- fan-exec.sh dispatch/adopt in a hermetic repo with a canned implementer
setup_fan_fixture fan-basic
fan_manifest="$TMP/fan-manifest.out"
check "fan dispatch manifest lists only gate passers" bash -c "
  cd '$FAN_PRIMARY' &&
  bash scripts/fan-exec.sh dispatch demo '$FAN_HANDOFF' 3 >'$fan_manifest' &&
  diff -u <(printf 'wt/demo-fan-2\nwt/demo-fan-3\n') '$fan_manifest'
"
check "fan adopt repoints canonical branch and cleans samples" bash -c "
  cd '$FAN_PRIMARY' &&
  bash scripts/fan-exec.sh adopt demo wt/demo-fan-3 &&
  [ \"\$(git rev-parse wt/demo)\" = \"\$(git -C '$FAN_WTS/demo' rev-parse HEAD)\" ] &&
  [ \"\$(cat '$FAN_WTS/demo/branch.txt')\" = 'wt/demo-fan-3' ] &&
  ! git show-ref --verify --quiet refs/heads/wt/demo-fan-1 &&
  ! git show-ref --verify --quiet refs/heads/wt/demo-fan-2 &&
  ! git show-ref --verify --quiet refs/heads/wt/demo-fan-3 &&
  [ ! -e '$FAN_WTS/demo-fan-1' ] &&
  [ ! -e '$FAN_WTS/demo-fan-2' ] &&
  [ ! -e '$FAN_WTS/demo-fan-3' ]
"
setup_fan_fixture fan-all-fail all-fail
fan_empty_manifest="$TMP/fan-empty-manifest.out"
check "fan dispatch emits empty manifest and exits 0 with no survivors" bash -c "
  cd '$FAN_PRIMARY' &&
  bash scripts/fan-exec.sh dispatch demo '$FAN_HANDOFF' 3 >'$fan_empty_manifest' &&
  [ ! -s '$fan_empty_manifest' ]
"

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

setup_release_fixture release-happy-primary 2026.8.9 "Code-review verdict: APPROVE" pass fresh
main_before=$(git -C "$REL_PRIMARY" rev-parse main)
check "release can be invoked from primary checkout" bash -c "
  cd '$REL_PRIMARY' &&
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
  [ \"\$(cat '$REL_PRIMARY/VERSION')\" = 2026.8.9 ] &&
  [ \"\$(cat '$REL_WORKTREE/VERSION')\" = 2026.8.10 ] &&
  ! git -C '$REL_WORKTREE' rev-parse --verify --quiet refs/tags/v2026.8.10
"

setup_release_fixture release-single 2026.8.9 "Code-review verdict: APPROVE" pass fresh
origin_before=$(git -C "$REL_PRIMARY" rev-parse origin/main)
main_before=$(git -C "$REL_PRIMARY" rev-parse main)
check "release commits bump on branch without touching main, origin/main, or tagging" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse main)\" = '$main_before' ] &&
  [ \"\$(git -C '$REL_PRIMARY' rev-parse origin/main)\" = '$origin_before' ] &&
  [ \"\$(cat VERSION)\" = 2026.8.10 ] &&
  [ \"\$(git log -1 --format=%s)\" = 'Release v2026.8.10' ] &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
"

setup_release_fixture release-sequential 2026.8.9 "Code-review verdict: APPROVE" pass fresh
check "release refuses stale branch, then computes next micro after sync" bash -c "
  set -e
  cd '$REL_WORKTREE'
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
  git push -q origin wt/demo:main
  rel_b='$TMP/release-sequential/b-wt'
  git -C '$REL_PRIMARY' branch wt/b main
  git -C '$REL_PRIMARY' worktree add -q \"\$rel_b\" wt/b
  git -C \"\$rel_b\" config user.email tester@example.com
  git -C \"\$rel_b\" config user.name Tester
  mkdir -p \"\$rel_b/work/b\"
  sed 's/# Demo/# B/' '$REL_WORKTREE/work/demo/plan.md' > \"\$rel_b/work/b/plan.md\"
  git -C \"\$rel_b\" add work/b/plan.md
  GIT_AUTHOR_DATE='2026-08-16T10:00:30Z' GIT_COMMITTER_DATE='2026-08-16T10:00:30Z' git -C \"\$rel_b\" commit -qm 'add b plan'
  stale_out='$TMP/release-stale.out'
  if PATH='$REL_FAKEBIN':\$PATH bash \"\$rel_b/scripts/release.sh\" b >\"\$stale_out\" 2>&1; then
    exit 1
  fi
  grep -q 'rebase/sync your branch onto origin/main' \"\$stale_out\"
  git -C \"\$rel_b\" fetch -q origin main
  git -C \"\$rel_b\" rebase -q origin/main
  cd \"\$rel_b\"
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh b
  [ \"\$(cat VERSION)\" = 2026.8.11 ] &&
  [ \"\$(git log -1 --format=%s)\" = 'Release v2026.8.11' ] &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.11
"

setup_release_fixture release-mid-gate 2026.8.9 "Code-review verdict: APPROVE" pass fresh
mkdir -p "$REL_WORKTREE/scripts/gate.d"
cat >"$REL_WORKTREE/scripts/gate.d/move-origin-main.sh" <<EOF
#!/usr/bin/env bash
set -euo pipefail
repo='$REL_PRIMARY'
printf 'merge during gate\n' >> "\$repo/remote-change.txt"
git -C "\$repo" add remote-change.txt
GIT_AUTHOR_DATE='2026-08-16T10:02:00Z' GIT_COMMITTER_DATE='2026-08-16T10:02:00Z' git -C "\$repo" commit -qm 'merge during gate'
git -C "\$repo" push -q origin main
EOF
chmod +x "$REL_WORKTREE/scripts/gate.d/move-origin-main.sh"
(
  cd "$REL_WORKTREE" || exit 1
  git add scripts/gate.d/move-origin-main.sh
  GIT_AUTHOR_DATE="2026-08-16T10:00:30Z" GIT_COMMITTER_DATE="2026-08-16T10:00:30Z" git commit -qm "add mid-gate hook"
)
check "release catches origin/main moving during gate" bash -c "
  cd '$REL_WORKTREE'
  mid_gate_out='$TMP/release-mid-gate.out'
  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo >\"\$mid_gate_out\" 2>&1; then
    exit 1
  fi
  grep -q 'rebase/sync your branch onto origin/main' \"\$mid_gate_out\"
"

setup_release_fixture release-tag-after-merge-happy 2026.8.9 "Code-review verdict: APPROVE" pass fresh
real_git=$(command -v git)
push_log="$TMP/tag-after-merge-push.log"
tag_guard_bin="$TMP/tag-after-merge-bin"
mkdir -p "$tag_guard_bin"
cat >"$tag_guard_bin/git" <<EOF
#!/usr/bin/env bash
if [[ "\$1" == push ]]; then
  printf 'unexpected push\n' >> "$push_log"
  exit 99
fi
"$real_git" "\$@"
EOF
chmod +x "$tag_guard_bin/git"
check "tag-after-merge creates local tag on origin/main and pushes nothing" bash -c "
  cd '$REL_WORKTREE' &&
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo &&
  git push -q origin wt/demo:main &&
  PATH='$tag_guard_bin:$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo &&
  [ \"\$(git rev-parse refs/tags/v2026.8.10)\" = \"\$(git rev-parse origin/main)\" ] &&
  [ ! -s '$push_log' ]
"

setup_release_fixture release-tag-after-merge-wrong-commit 2026.8.9 "Code-review verdict: APPROVE" pass fresh
check "tag-after-merge refuses when origin/main advanced past the release" bash -c "
  set -e
  cd '$REL_WORKTREE'
  PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh demo
  git push -q origin wt/demo:main
  git -C '$REL_PRIMARY' fetch -q origin main
  git -C '$REL_PRIMARY' reset -q --hard origin/main
  printf 'next change\n' > '$REL_PRIMARY/after-release.txt'
  git -C '$REL_PRIMARY' add after-release.txt
  GIT_AUTHOR_DATE='2026-08-16T10:03:00Z' GIT_COMMITTER_DATE='2026-08-16T10:03:00Z' git -C '$REL_PRIMARY' commit -qm 'Next change'
  git -C '$REL_PRIMARY' push -q origin main
  wrong_out='$TMP/tag-after-merge-wrong.out'
  if PATH='$REL_FAKEBIN':\$PATH bash scripts/release.sh tag-after-merge demo >\"\$wrong_out\" 2>&1; then
    exit 1
  fi
  grep -q 'origin/main is not Release v2026.8.10' \"\$wrong_out\" &&
  ! git rev-parse --verify --quiet refs/tags/v2026.8.10
"

# --- gate.sh runs and exits cleanly on this repo
check "gate.sh runs on this repo" bash scripts/gate.sh

echo
echo "passed: $pass, failed: $fail"
exit "$((fail > 0 ? 1 : 0))"
