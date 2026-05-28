#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-issues.sh [remote-or-url] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--state open|closed|all] [--limit n]

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
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown argument: $1" 2
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
    exec "$(script_dir)/gh/get-issues.sh" --repo "$repo" --state "$state" --limit "$limit"
    ;;
  gitlab)
    exec "$(script_dir)/glab/get-issues.sh" --repo "$repo" --state "$state" --limit "$limit"
    ;;
  *)
    die "Could not determine issue host. Use --host github or --host gitlab." 2
    ;;
esac
