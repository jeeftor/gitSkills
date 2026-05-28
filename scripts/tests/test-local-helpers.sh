#!/bin/sh
set -eu

unset CDPATH

die() {
  echo "$1" >&2
  exit "${2:-1}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Missing required command: $1" 127
  fi
}

assert_json() {
  file="$1"
  filter="$2"
  description="$3"

  if ! jq -e "$filter" "$file" >/dev/null; then
    echo "Assertion failed: $description" >&2
    echo "Filter: $filter" >&2
    jq . "$file" >&2 || true
    exit 1
  fi
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gitSkills-local-helpers.XXXXXX")"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

require_command git
require_command jq

# Keep fixture behavior independent of the developer's global Git config.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

fixture="$tmp_dir/repo"
mkdir "$fixture"
cd "$fixture"
fixture="$(pwd -P)"

git -c init.defaultBranch=master init >/dev/null
git checkout -B master >/dev/null 2>&1
git config user.name "gitSkills Test"
git config user.email "gitskills@example.invalid"
git config commit.gpgsign false

printf '%s\n' "base" >README.md
git add README.md
git commit -m "initial fixture commit" >/dev/null

git remote add origin https://github.com/example/repo.git
git remote add gitlab git@gitlab.example.com:group/project.git
git update-ref refs/remotes/origin/master HEAD
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master

git checkout -b feature/helper-smoke >/dev/null 2>&1
git branch --set-upstream-to=origin/master feature/helper-smoke >/dev/null
printf '%s\n' "feature" >feature.txt
git add feature.txt
git commit -m "feature fixture commit" >/dev/null

printf '%s\n' "staged" >staged.txt
git add staged.txt
printf '%s\n' "changed" >>README.md
printf '%s\n' "untracked" >untracked.txt

resolve_json="$tmp_dir/resolve-target.json"
"$repo_root/scripts/git/resolve-target.sh" >"$resolve_json"
assert_json "$resolve_json" '.host == "github"' "default target resolves the branch upstream host"
assert_json "$resolve_json" '.repo == "example/repo"' "default target resolves the branch upstream repo"
assert_json "$resolve_json" '.source == "branch_upstream"' "default target records branch upstream source"
assert_json "$resolve_json" '.remote == "origin"' "default target records upstream remote"
assert_json "$resolve_json" '.url == "https://github.com/example/repo.git"' "default target records remote URL"

gitlab_json="$tmp_dir/resolve-gitlab.json"
"$repo_root/scripts/git/resolve-target.sh" gitlab >"$gitlab_json"
assert_json "$gitlab_json" '.host == "gitlab"' "named GitLab remote resolves host"
assert_json "$gitlab_json" '.repo == "group/project"' "named GitLab remote resolves repo"
assert_json "$gitlab_json" '.source == "remote"' "named remote records remote source"
assert_json "$gitlab_json" '.remote == "gitlab"' "named remote records remote name"

all_remotes_json="$tmp_dir/resolve-all-remotes.json"
"$repo_root/scripts/git/resolve-target.sh" --all-remotes >"$all_remotes_json"
assert_json "$all_remotes_json" '.host == "mixed"' "all-remotes target reports mixed host"
assert_json "$all_remotes_json" '.repo == null' "all-remotes target has null top-level repo"
assert_json "$all_remotes_json" '.targets | length == 2' "all-remotes target deduplicates repositories"
assert_json "$all_remotes_json" '.targets | any(.host == "github" and .repo == "example/repo")' "all-remotes includes GitHub target"
assert_json "$all_remotes_json" '.targets | any(.host == "gitlab" and .repo == "group/project")' "all-remotes includes GitLab target"

branch_state_json="$tmp_dir/branch-state.json"
"$repo_root/scripts/git/get-branch-state.sh" >"$branch_state_json"
assert_json "$branch_state_json" '.repo.root == "'"$fixture"'"' "branch state records repository root"
assert_json "$branch_state_json" '.current_branch == "feature/helper-smoke"' "branch state records current branch"
assert_json "$branch_state_json" '.is_detached == false' "branch state records attached HEAD"
assert_json "$branch_state_json" '.current_head != null' "branch state records current HEAD"
assert_json "$branch_state_json" '.upstream.exists == true' "branch state records existing upstream"
assert_json "$branch_state_json" '.upstream.ref == "origin/master"' "branch state records upstream ref"
assert_json "$branch_state_json" '.base.exists == true' "branch state records existing base"
assert_json "$branch_state_json" '.base.branch == "master"' "branch state records base branch"
assert_json "$branch_state_json" '.base.remote == "origin"' "branch state records base remote"
assert_json "$branch_state_json" '.dirty.is_dirty == true' "branch state records dirty worktree"
assert_json "$branch_state_json" '.dirty.summary.staged == 1' "branch state counts staged entries"
assert_json "$branch_state_json" '.dirty.summary.unstaged == 1' "branch state counts unstaged entries"
assert_json "$branch_state_json" '.dirty.summary.untracked == 1' "branch state counts untracked entries"
assert_json "$branch_state_json" '.dirty.staged | any(.status == "A" and .path == "staged.txt")' "branch state lists staged file"
assert_json "$branch_state_json" '.dirty.unstaged | any(.status == "M" and .path == "README.md")' "branch state lists unstaged file"
assert_json "$branch_state_json" '.dirty.untracked | any(.status == "??" and .path == "untracked.txt")' "branch state lists untracked file"
assert_json "$branch_state_json" '.ahead_behind.upstream.ahead == 1' "branch state records upstream ahead count"
assert_json "$branch_state_json" '.ahead_behind.upstream.behind == 0' "branch state records upstream behind count"
assert_json "$branch_state_json" '.ahead_behind.base.ahead == 1' "branch state records base ahead count"
assert_json "$branch_state_json" '.ahead_behind.base.behind == 0' "branch state records base behind count"

echo "Local helper JSON smoke tests passed."
