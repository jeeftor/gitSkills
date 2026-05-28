#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-ci.sh [remote-or-url|all remotes] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--target-type pr|mr|branch|commit|run|pipeline] [--target value] [--limit n] [--all-remotes]

Collect CI status as normalized JSON after resolving the current GitHub or GitLab repository.
The script is read-only and delegates to the provider-specific CI collector.
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

provider_target_type() {
  target_host="$1"
  requested_type="$2"

  case "$target_host" in
    github)
      case "$requested_type" in
        pr|branch|commit|run) printf '%s\n' "$requested_type" ;;
        mr) printf '%s\n' "pr" ;;
        pipeline) die "GitHub CI does not support --target-type pipeline; use run" 2 ;;
        *) die "Unsupported --target-type value: $requested_type" 2 ;;
      esac
      ;;
    gitlab)
      case "$requested_type" in
        mr|branch|commit|pipeline) printf '%s\n' "$requested_type" ;;
        pr) printf '%s\n' "mr" ;;
        run) die "GitLab CI does not support --target-type run; use pipeline" 2 ;;
        *) die "Unsupported --target-type value: $requested_type" 2 ;;
      esac
      ;;
    *)
      die "Could not determine CI host. Use --host github or --host gitlab." 2
      ;;
  esac
}

collect_target() {
  target_host="$1"
  target_repo="$2"
  provider_type="$(provider_target_type "$target_host" "$target_type")"

  set -- --repo "$target_repo" --target-type "$provider_type" --limit "$limit"
  if [ -n "$target_value" ]; then
    set -- "$@" --target "$target_value"
  fi

  case "$target_host" in
    github)
      "$(script_dir)/gh/get-ci.sh" "$@"
      ;;
    gitlab)
      "$(script_dir)/glab/get-ci.sh" "$@"
      ;;
    *)
      die "Could not determine CI host. Use --host github or --host gitlab." 2
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
    --arg target_type "$target_type" \
    --arg target_value "$target_value" \
    --argjson limit "$limit" '
    def aggregate($statuses):
      if ($statuses | length) == 0 then "Missing"
      elif any($statuses[]; . == "Failing") then "Failing"
      elif any($statuses[]; . == "Canceled") then "Canceled"
      elif any($statuses[]; . == "Pending") then "Pending"
      elif all($statuses[]; . == "Skipped") then "Skipped"
      elif all($statuses[]; . == "Missing") then "Missing"
      elif all($statuses[]; (. == "Pass" or . == "Skipped")) then "Pass"
      else "Unknown"
      end;
    {
      host: "mixed",
      repo: null,
      target: {type: $target_type, value: (if $target_value == "" then null else $target_value end)},
      status: aggregate([.[] | .status]),
      limit: $limit,
      targets: .
    }' \
    "$results_file"
}

host=""
repo=""
remote=""
target_repo=""
target_type="branch"
target_value=""
limit="20"
all_remotes=0

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
    --target-type)
      target_type="${2:?missing value for --target-type}"
      shift 2
      ;;
    --target)
      target_value="${2:?missing value for --target}"
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
        if [ -n "$target_repo" ]; then
          die "Only one remote or URL target is supported" 2
        fi
        target_repo="$1"
        shift
      fi
      ;;
    remotes)
      die "Use 'all remotes' or --all-remotes for multi-remote collection" 2
      ;;
    *)
      if [ -n "$target_repo" ]; then
        die "Only one remote or URL target is supported" 2
      fi
      target_repo="$1"
      shift
      ;;
  esac
done

case "$host" in
  ""|github|gitlab) ;;
  *) die "Unsupported --host value: $host" 2 ;;
esac

case "$target_type" in
  pr|mr|branch|commit|run|pipeline) ;;
  *) die "Unsupported --target-type value: $target_type" 2 ;;
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

if [ -n "$remote" ] && [ -n "$target_repo" ]; then
  die "Use either --remote or a positional remote/URL target, not both" 2
fi

require_command jq

if [ "$all_remotes" -eq 1 ]; then
  if [ -n "$remote" ] || [ -n "$target_repo" ] || [ -n "$repo" ]; then
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
elif [ -n "$target_repo" ]; then
  set -- "$@" "$target_repo"
fi
resolved_json="$("$@")"
resolved_host="$(printf '%s\n' "$resolved_json" | jq -r '.host')"
resolved_repo="$(printf '%s\n' "$resolved_json" | jq -r '.repo')"

collect_target "$resolved_host" "$resolved_repo"
