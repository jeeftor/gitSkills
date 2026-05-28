#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-branch-state.sh [--base branch-or-ref]

Inspect the current Git branch state as structured JSON for PR/MR create and update workflows.
The script is read-only and uses only local Git metadata.
EOF
}

die() {
  echo "$1" >&2
  exit "${2:-1}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Missing required command: $1" 127
  fi
}

commit_for_ref() {
  git rev-parse --verify -q "$1^{commit}" 2>/dev/null || true
}

ahead_behind_json() {
  compare_ref="$1"

  if [ -z "$current_head" ] || [ -z "$compare_ref" ]; then
    printf '%s\n' "null"
    return
  fi

  if ! git rev-parse --verify -q "$compare_ref^{commit}" >/dev/null 2>&1; then
    printf '%s\n' "null"
    return
  fi

  counts="$(git rev-list --left-right --count "HEAD...$compare_ref" 2>/dev/null)" || {
    printf '%s\n' "null"
    return
  }

  # Intentionally split the two numeric fields emitted by git rev-list.
  # shellcheck disable=SC2086
  set -- $counts
  jq -n --argjson ahead "$1" --argjson behind "$2" \
    '{ahead: $ahead, behind: $behind}'
}

status_json() {
  git status --porcelain=v1 --untracked-files=all |
    jq -Rcs '
      split("\n") | map(select(length > 0)) as $lines |
      def staged_entry($line): {status: $line[0:1], path: $line[3:]};
      def unstaged_entry($line): {status: $line[1:2], path: $line[3:]};
      def untracked_entry($line): {status: "??", path: $line[3:]};
      ($lines | map(select(.[0:2] == "??") | untracked_entry(.))) as $untracked |
      ($lines | map(select(.[0:2] != "??" and .[0:1] != " ") | staged_entry(.))) as $staged |
      ($lines | map(select(.[0:2] != "??" and .[1:2] != " ") | unstaged_entry(.))) as $unstaged |
      {
        is_dirty: (($staged | length) > 0 or ($unstaged | length) > 0 or ($untracked | length) > 0),
        summary: {
          staged: ($staged | length),
          unstaged: ($unstaged | length),
          untracked: ($untracked | length)
        },
        staged: $staged,
        unstaged: $unstaged,
        untracked: $untracked
      }
    '
}

set_base_from_remote_head() {
  candidate_remote="$1"
  candidate_source="$2"

  candidate_symbolic="$(git symbolic-ref -q --short "refs/remotes/$candidate_remote/HEAD" 2>/dev/null || true)"
  case "$candidate_symbolic" in
    "$candidate_remote"/*)
      candidate_branch="${candidate_symbolic#"${candidate_remote}"/}"
      candidate_ref="refs/remotes/$candidate_remote/$candidate_branch"
      candidate_head="$(commit_for_ref "$candidate_ref")"
      if [ -n "$candidate_head" ]; then
        base_name="$candidate_branch"
        base_remote="$candidate_remote"
        base_ref="$candidate_ref"
        base_head="$candidate_head"
        base_source="$candidate_source"
        return 0
      fi
      ;;
  esac

  return 1
}

set_base_from_remote_branch() {
  candidate_remote="$1"
  candidate_branch="$2"
  candidate_source="$3"
  candidate_ref="refs/remotes/$candidate_remote/$candidate_branch"
  candidate_head="$(commit_for_ref "$candidate_ref")"

  if [ -n "$candidate_head" ]; then
    base_name="$candidate_branch"
    base_remote="$candidate_remote"
    base_ref="$candidate_ref"
    base_head="$candidate_head"
    base_source="$candidate_source"
    return 0
  fi

  return 1
}

set_base_from_local_branch() {
  candidate_branch="$1"
  candidate_source="$2"
  candidate_ref="refs/heads/$candidate_branch"
  candidate_head="$(commit_for_ref "$candidate_ref")"

  if [ -n "$candidate_head" ]; then
    base_name="$candidate_branch"
    base_remote=""
    base_ref="$candidate_ref"
    base_head="$candidate_head"
    base_source="$candidate_source"
    return 0
  fi

  return 1
}

set_base_from_override() {
  candidate_name="$1"

  for candidate_ref in "$candidate_name" "refs/heads/$candidate_name" "refs/remotes/$candidate_name"; do
    candidate_head="$(commit_for_ref "$candidate_ref")"
    if [ -n "$candidate_head" ]; then
      case "$candidate_ref" in
        refs/remotes/*/*)
          remote_branch="${candidate_ref#refs/remotes/}"
          base_remote="${remote_branch%%/*}"
          base_name="${remote_branch#*/}"
          ;;
        refs/heads/*)
          base_remote=""
          base_name="${candidate_ref#refs/heads/}"
          ;;
        */*)
          base_remote="${candidate_ref%%/*}"
          base_name="${candidate_ref#*/}"
          ;;
        *)
          base_remote=""
          base_name="$candidate_ref"
          ;;
      esac
      base_ref="$candidate_ref"
      base_head="$candidate_head"
      base_source="override"
      return 0
    fi
  done

  base_name="$candidate_name"
  base_remote=""
  base_ref=""
  base_head=""
  base_source="override_unresolved"
  return 0
}

guess_base() {
  if [ -n "$base_override" ]; then
    set_base_from_override "$base_override"
    return
  fi

  if [ -n "$upstream_remote" ]; then
    set_base_from_remote_head "$upstream_remote" "upstream_remote_head" && return
  fi

  set_base_from_remote_head origin "origin_head" && return
  set_base_from_remote_head upstream "upstream_head" && return
  set_base_from_remote_branch origin master "origin_master" && return
  set_base_from_remote_branch origin main "origin_main" && return
  set_base_from_remote_branch upstream master "upstream_master" && return
  set_base_from_remote_branch upstream main "upstream_main" && return
  set_base_from_local_branch master "local_master" && return
  set_base_from_local_branch main "local_main" && return
}

base_override=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --base)
      base_override="${2:?missing value for --base}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown argument: $1" 2
      ;;
    *)
      die "Unexpected argument: $1" 2
      ;;
  esac
done

require_command git
require_command jq

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "Not inside a Git working tree" 2
cd "$repo_root"

current_head="$(commit_for_ref HEAD)"
current_branch="$(git symbolic-ref -q --short HEAD 2>/dev/null || true)"
if [ -n "$current_branch" ]; then
  is_detached="false"
else
  is_detached="true"
fi

upstream_ref="$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null || true)"
upstream_remote=""
upstream_branch=""
upstream_head=""
if [ -n "$upstream_ref" ]; then
  case "$upstream_ref" in
    */*)
      upstream_remote="${upstream_ref%%/*}"
      upstream_branch="${upstream_ref#*/}"
      ;;
  esac
  upstream_head="$(commit_for_ref "$upstream_ref")"
fi

pushed_remote=""
pushed_branch=""
pushed_ref=""
pushed_head=""
pushed_source="unresolved"
if [ -n "$current_branch" ]; then
  pushed_remote="$(git config "branch.$current_branch.pushRemote" 2>/dev/null || true)"
  if [ -n "$pushed_remote" ]; then
    pushed_source="branch_push_remote"
  else
    pushed_remote="$(git config remote.pushDefault 2>/dev/null || true)"
    if [ -n "$pushed_remote" ]; then
      pushed_source="remote_push_default"
    elif [ -n "$upstream_remote" ]; then
      pushed_remote="$upstream_remote"
      pushed_source="upstream_remote"
    elif git remote get-url origin >/dev/null 2>&1; then
      pushed_remote="origin"
      pushed_source="origin_fallback"
    fi
  fi

  if [ -n "$pushed_remote" ]; then
    if [ "$pushed_remote" = "$upstream_remote" ] && [ -n "$upstream_branch" ]; then
      pushed_branch="$upstream_branch"
    else
      pushed_branch="$current_branch"
    fi
    pushed_ref="refs/remotes/$pushed_remote/$pushed_branch"
    pushed_head="$(commit_for_ref "$pushed_ref")"
  fi
fi

base_name=""
base_remote=""
base_ref=""
base_head=""
base_source="unknown"
guess_base

dirty_json="$(status_json)"
upstream_ahead_behind_json="$(ahead_behind_json "$upstream_ref")"
base_ahead_behind_json="$(ahead_behind_json "$base_ref")"
pushed_ahead_behind_json="$(ahead_behind_json "$pushed_ref")"

jq -n \
  --arg repo_root "$repo_root" \
  --arg current_branch "$current_branch" \
  --arg is_detached "$is_detached" \
  --arg current_head "$current_head" \
  --arg upstream_ref "$upstream_ref" \
  --arg upstream_remote "$upstream_remote" \
  --arg upstream_branch "$upstream_branch" \
  --arg upstream_head "$upstream_head" \
  --arg pushed_remote "$pushed_remote" \
  --arg pushed_branch "$pushed_branch" \
  --arg pushed_ref "$pushed_ref" \
  --arg pushed_head "$pushed_head" \
  --arg pushed_source "$pushed_source" \
  --arg base_name "$base_name" \
  --arg base_remote "$base_remote" \
  --arg base_ref "$base_ref" \
  --arg base_head "$base_head" \
  --arg base_source "$base_source" \
  --argjson dirty "$dirty_json" \
  --argjson upstream_ahead_behind "$upstream_ahead_behind_json" \
  --argjson base_ahead_behind "$base_ahead_behind_json" \
  --argjson pushed_ahead_behind "$pushed_ahead_behind_json" '
  def null_if_empty($value): if $value == "" then null else $value end;
  {
    repo: {
      root: $repo_root
    },
    current_branch: null_if_empty($current_branch),
    is_detached: ($is_detached == "true"),
    current_head: null_if_empty($current_head),
    upstream: {
      ref: null_if_empty($upstream_ref),
      remote: null_if_empty($upstream_remote),
      branch: null_if_empty($upstream_branch),
      head: null_if_empty($upstream_head),
      exists: ($upstream_head != "")
    },
    pushed: {
      remote: null_if_empty($pushed_remote),
      branch: null_if_empty($pushed_branch),
      ref: null_if_empty($pushed_ref),
      head: null_if_empty($pushed_head),
      exists: ($pushed_head != ""),
      source: $pushed_source
    },
    base: {
      branch: null_if_empty($base_name),
      remote: null_if_empty($base_remote),
      ref: null_if_empty($base_ref),
      head: null_if_empty($base_head),
      exists: ($base_head != ""),
      source: $base_source,
      is_current_branch: ($current_branch != "" and $base_name != "" and $current_branch == $base_name)
    },
    dirty: $dirty,
    ahead_behind: {
      upstream: $upstream_ahead_behind,
      base: $base_ahead_behind,
      pushed: $pushed_ahead_behind
    }
  }
'
