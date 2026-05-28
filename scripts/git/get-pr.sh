#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-pr.sh [remote-or-url|pr-url|mr-url|number] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--number n] [--branch branch]

Collect one GitHub pull request or GitLab merge request as normalized JSON after resolving the repository target.
The script is read-only and delegates to the provider-specific detail collector.
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

number_value() {
  value="$1"
  value="${value#\#}"
  value="${value#!}"
  value="${value%%/*}"
  value="${value%%\?*}"
  value="${value%%\#*}"
  case "$value" in
    ''|*[!0-9]*) return 1 ;;
    *) printf '%s\n' "$value" ;;
  esac
}

parse_pr_url() {
  url="$1"

  case "$url" in
    *github.com/*/pull/*)
      path="${url#*github.com/}"
      detected_host="github"
      detected_repo="${path%%/pull/*}"
      detected_number="${path#*/pull/}"
      ;;
    *gitlab*/*/-/merge_requests/*)
      path="${url#*://}"
      path="${path#*/}"
      detected_host="gitlab"
      detected_repo="${path%%/-/merge_requests/*}"
      detected_number="${path#*/-/merge_requests/}"
      ;;
    *)
      return 1
      ;;
  esac

  detected_number="$(number_value "$detected_number")" || return 1
  host="$detected_host"
  repo="$detected_repo"
  number="$detected_number"
}

host=""
repo=""
remote=""
target=""
number=""
branch=""

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
    --number)
      number="$(number_value "${2:?missing value for --number}")" || die "--number must be a PR number or MR IID" 2
      shift 2
      ;;
    --branch)
      branch="${2:?missing value for --branch}"
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
      if parse_pr_url "$1"; then
        shift
      elif parsed_number="$(number_value "$1" 2>/dev/null)"; then
        if [ -n "$number" ]; then
          die "Only one PR number, MR IID, or URL is supported" 2
        fi
        number="$parsed_number"
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

if [ -n "$remote" ] && [ -n "$target" ]; then
  die "Use either --remote or a positional remote/URL target, not both" 2
fi

if [ -n "$number" ] && [ -n "$branch" ]; then
  die "Use either --number or --branch, not both" 2
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

set -- --repo "$repo"
if [ -n "$number" ]; then
  set -- "$@" --number "$number"
elif [ -n "$branch" ]; then
  set -- "$@" --branch "$branch"
fi

case "$host" in
  github)
    exec "$(script_dir)/gh/get-pr.sh" "$@"
    ;;
  gitlab)
    exec "$(script_dir)/glab/get-mr.sh" "$@"
    ;;
  *)
    die "Could not determine PR/MR host. Use --host github or --host gitlab." 2
    ;;
esac
