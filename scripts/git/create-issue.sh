#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/create-issue.sh [remote-or-url] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] --title title [--body text|--body-file file] [--duplicate-limit n] [--allow-duplicate] [--yes]

Resolve the current GitHub or GitLab repository and create an issue through the provider helper.
Without --yes, the script only resolves the target and searches for likely duplicate open issues.
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
title=""
body=""
body_file=""
duplicate_limit="10"
allow_duplicate="0"
assume_yes="0"

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
    --title)
      title="${2:?missing value for --title}"
      shift 2
      ;;
    --body)
      body="${2:?missing value for --body}"
      shift 2
      ;;
    --body-file)
      body_file="${2:?missing value for --body-file}"
      shift 2
      ;;
    --duplicate-limit)
      duplicate_limit="${2:?missing value for --duplicate-limit}"
      shift 2
      ;;
    --allow-duplicate)
      allow_duplicate="1"
      shift
      ;;
    --yes)
      assume_yes="1"
      shift
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

[ -n "$title" ] || die "--title is required" 2

if [ -n "$body" ] && [ -n "$body_file" ]; then
  die "Use either --body or --body-file, not both" 2
fi

case "$duplicate_limit" in
  ''|*[!0-9]*)
    die "--duplicate-limit must be a positive integer" 2
    ;;
  *)
    if [ "$duplicate_limit" -eq 0 ]; then
      die "--duplicate-limit must be a positive integer" 2
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

set -- --repo "$repo" --title "$title" --duplicate-limit "$duplicate_limit"

if [ -n "$body" ]; then
  set -- "$@" --body "$body"
fi

if [ -n "$body_file" ]; then
  set -- "$@" --body-file "$body_file"
fi

if [ "$allow_duplicate" = "1" ]; then
  set -- "$@" --allow-duplicate
fi

if [ "$assume_yes" = "1" ]; then
  set -- "$@" --yes
fi

case "$host" in
  github)
    exec "$(script_dir)/gh/create-issue.sh" "$@"
    ;;
  gitlab)
    exec "$(script_dir)/glab/create-issue.sh" "$@"
    ;;
  *)
    die "Could not determine issue host. Use --host github or --host gitlab." 2
    ;;
esac
