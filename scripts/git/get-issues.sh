#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-issues.sh [remote-or-url|all remotes] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--state open|closed|all] [--limit n] [--all-remotes]

Collect issues as normalized JSON after resolving the current GitHub or GitLab repository.
The script is read-only and delegates to the provider-specific issue collector.
EOF
}

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
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

host=""
repo=""
remote=""
target=""
state="open"
limit="50"
all_remotes=0

collect_target() {
  target_host="$1"
  target_repo="$2"

  case "$target_host" in
    github)
      "$(script_dir)/gh/get-issues.sh" --repo "$target_repo" --state "$state" --limit "$limit"
      ;;
    gitlab)
      "$(script_dir)/glab/get-issues.sh" --repo "$target_repo" --state "$state" --limit "$limit"
      ;;
    *)
      die "Could not determine issue host. Use --host github or --host gitlab." 2
      ;;
  esac
}

collect_all_remotes() {
  results_file="$(mktemp)"
  trap 'rm -f "$results_file"' EXIT HUP INT TERM

  target_json="$("$(script_dir)/resolve-target.sh" --all-remotes)"
  printf '%s\n' "$target_json" |
    jq -c '.targets[]' |
    while IFS= read -r resolved_target; do
      target_host="$(printf '%s\n' "$resolved_target" | jq -r '.host')"
      target_repo="$(printf '%s\n' "$resolved_target" | jq -r '.repo')"
      collect_target "$target_host" "$target_repo" >>"$results_file"
    done

  jq -s \
    --arg state "$state" \
    --argjson limit "$limit" \
    '{
      host: "mixed",
      repo: null,
      state: $state,
      limit: $limit,
      targets: .,
      issues: ([.[] | .issues[]])
    }' \
    "$results_file"
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      host="${2:?missing value for --host}"
      shift 2
      ;;
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --remote)
      remote="${2:?missing value for --remote}"
      shift 2
      ;;
    --state)
      state="${2:?missing value for --state}"
      shift 2
      ;;
    --limit)
      limit="${2:?missing value for --limit}"
      shift 2
      ;;
    --all-remotes)
      all_remotes=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown argument: $1" 2
      ;;
    all)
      if [ "$#" -gt 1 ] && [ "$2" = "remotes" ]; then
        all_remotes=1
        shift 2
      else
        if [ -n "$target" ]; then
          die "Only one remote or URL target is supported" 2
        fi
        target="$1"
        shift
      fi
      ;;
    remotes)
      die "Use 'all remotes' or --all-remotes for multi-remote collection" 2
      ;;
    *)
      if [ -n "$target" ]; then
        die "Only one remote or URL target is supported" 2
      fi
      target="$1"
      shift
      ;;
  esac
done

case "$host" in
  ""|github|gitlab) ;;
  *) die "Unsupported --host value: $host" 2 ;;
esac

case "$limit" in
  ''|*[!0-9]*)
    die "--limit must be a positive integer" 2
    ;;
  *)
    if [ "$limit" -eq 0 ]; then
      die "--limit must be a positive integer" 2
    fi
    ;;
esac

if [ -n "$remote" ] && [ -n "$target" ]; then
  die "Use either --remote or a positional remote/URL target, not both" 2
fi

require_command jq

if [ "$all_remotes" -eq 1 ]; then
  if [ -n "$remote" ] || [ -n "$target" ] || [ -n "$repo" ]; then
    die "Use all-remotes collection without --repo, --remote, or a positional target" 2
  fi
  collect_all_remotes
  exit 0
fi

set -- "$(script_dir)/resolve-target.sh"
if [ -n "$host" ]; then
  set -- "$@" --host "$host"
fi
if [ -n "$repo" ]; then
  set -- "$@" --repo "$repo"
fi
if [ -n "$remote" ]; then
  set -- "$@" --remote "$remote"
elif [ -n "$target" ]; then
  set -- "$@" "$target"
fi
target_json="$("$@")"
host="$(printf '%s\n' "$target_json" | jq -r '.host')"
repo="$(printf '%s\n' "$target_json" | jq -r '.repo')"

collect_target "$host" "$repo"
