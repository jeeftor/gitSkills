#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-issue.sh [remote-or-url] [issue-number-or-url] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--issue n]

Collect one issue as normalized JSON after resolving the current GitHub or GitLab repository.
The script is read-only and delegates to the provider-specific issue detail collector.
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

remote_host() {
  case "$1" in
    *github.com[:/]*)
      printf '%s\n' "github"
      ;;
    *gitlab*[:/]*)
      printf '%s\n' "gitlab"
      ;;
    *)
      return 1
      ;;
  esac
}

issue_number() {
  value="$1"
  value="${value#\#}"
  value="${value%%/*}"
  value="${value%%\?*}"
  value="${value%%\#*}"

  case "$value" in
    ''|*[!0-9]*)
      return 1
      ;;
    *)
      printf '%s\n' "$value"
      ;;
  esac
}

parse_issue_url() {
  url="$1"

  case "$url" in
    *github.com/*/issues/*)
      path="${url#*github.com/}"
      detected_repo="${path%%/issues/*}"
      detected_issue="${path#*/issues/}"
      ;;
    *gitlab*/*/-/issues/*)
      path="${url#*://}"
      path="${path#*/}"
      detected_repo="${path%%/-/issues/*}"
      detected_issue="${path#*/-/issues/}"
      ;;
    *gitlab*/*/-/work_items/*)
      path="${url#*://}"
      path="${path#*/}"
      detected_repo="${path%%/-/work_items/*}"
      detected_issue="${path#*/-/work_items/}"
      ;;
    *)
      return 1
      ;;
  esac

  detected_host="$(remote_host "$url")" || return 1
  detected_issue="$(issue_number "$detected_issue")" || return 1

  host="$detected_host"
  repo="$detected_repo"
  issue="$detected_issue"
}

host=""
repo=""
remote=""
target=""
issue=""

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
    --issue)
      issue="$(issue_number "${2:?missing value for --issue}")" || die "--issue must be an issue number" 2
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
      if parse_issue_url "$1"; then
        shift
      elif parsed_issue="$(issue_number "$1" 2>/dev/null)"; then
        if [ -n "$issue" ]; then
          die "Only one issue number or URL is supported" 2
        fi
        issue="$parsed_issue"
        shift
      else
        if [ -n "$target" ]; then
          die "Only one remote or URL target is supported" 2
        fi
        target="$1"
        shift
      fi
      ;;
  esac
done

case "$host" in
  ""|github|gitlab) ;;
  *) die "Unsupported --host value: $host" 2 ;;
esac

[ -n "$issue" ] || die "--issue or an issue URL is required" 2

if [ -n "$remote" ] && [ -n "$target" ]; then
  die "Use either --remote or a positional remote/URL target, not both" 2
fi

require_command jq

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

case "$host" in
  github)
    exec "$(script_dir)/gh/get-issue.sh" --repo "$repo" --issue "$issue"
    ;;
  gitlab)
    exec "$(script_dir)/glab/get-issue.sh" --repo "$repo" --issue "$issue"
    ;;
  *)
    die "Could not determine issue host. Use --host github or --host gitlab." 2
    ;;
esac
