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

remote_repo() {
  url="$1"

  case "$url" in
    *://*)
      path="${url#*://}"
      path="${path#*@}"
      path="${path#*/}"
      ;;
    *:*)
      path="${url#*:}"
      ;;
    *)
      path="${url#*/}"
      ;;
  esac

  path="${path%.git}"
  path="${path#/}"

  case "$path" in
    */*) printf '%s\n' "$path" ;;
    *) return 1 ;;
  esac
}

resolve_remote() {
  remote_name="$1"

  url="$(git remote get-url "$remote_name" 2>/dev/null)" || return 1
  detected_host="$(remote_host "$url")" || return 1
  detected_repo="$(remote_repo "$url")" || return 1

  host="$detected_host"
  repo="$detected_repo"
}

resolve_url() {
  url="$1"

  detected_host="$(remote_host "$url")" || return 1
  detected_repo="$(remote_repo "$url")" || return 1

  host="$detected_host"
  repo="$detected_repo"
}

resolve_target() {
  target="$1"

  resolve_remote "$target" && return 0
  resolve_url "$target" && return 0
  return 1
}

resolve_from_upstream() {
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)" || return 1
  case "$upstream" in
    */*) resolve_remote "${upstream%%/*}" ;;
    *) return 1 ;;
  esac
}

resolve_from_known_remotes() {
  resolve_from_upstream && return 0
  resolve_remote origin && return 0
  resolve_remote upstream && return 0
  return 1
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

if [ -n "$remote" ]; then
  require_command git
  resolve_remote "$remote" || die "Could not resolve GitHub or GitLab repository from remote: $remote" 2
elif [ -n "$target" ]; then
  require_command git
  resolve_target "$target" || die "Could not resolve GitHub or GitLab repository from target: $target" 2
elif [ -z "$repo" ]; then
  require_command git
  resolve_from_known_remotes || die "Could not resolve GitHub or GitLab repository from branch upstream, origin, or upstream" 2
elif [ -z "$host" ]; then
  host="github"
fi

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
    exec "$(script_dir)/gh-create-issue.sh" "$@"
    ;;
  gitlab)
    exec "$(script_dir)/glab-create-issue.sh" "$@"
    ;;
  *)
    die "Could not determine issue host. Use --host github or --host gitlab." 2
    ;;
esac
