#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/resolve-target.sh [remote-or-url] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--all-remotes]

Resolve the current GitHub or GitLab repository target as normalized JSON.
The script is read-only and does not call platform APIs.
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

json_target() {
  target_host="$1"
  target_repo="$2"
  target_source="$3"
  target_remote="$4"
  target_url="$5"

  jq -n \
    --arg host "$target_host" \
    --arg repo "$target_repo" \
    --arg source "$target_source" \
    --arg remote "$target_remote" \
    --arg url "$target_url" '
    def null_if_empty($value): if $value == "" then null else $value end;
    {
      host: $host,
      repo: $repo,
      source: $source,
      remote: null_if_empty($remote),
      url: null_if_empty($url)
    }'
}

resolve_remote_json() {
  remote_name="$1"
  source="$2"

  url="$(git remote get-url "$remote_name" 2>/dev/null)" || return 1
  detected_host="$(remote_host "$url")" || return 1
  detected_repo="$(remote_repo "$url")" || return 1

  json_target "$detected_host" "$detected_repo" "$source" "$remote_name" "$url"
}

resolve_url_json() {
  url="$1"
  detected_host="$(remote_host "$url")" || return 1
  detected_repo="$(remote_repo "$url")" || return 1

  json_target "$detected_host" "$detected_repo" "url" "" "$url"
}

resolve_target_json() {
  target="$1"

  resolve_remote_json "$target" "remote" && return 0
  resolve_url_json "$target" && return 0
  return 1
}

resolve_from_upstream_json() {
  upstream="$(git rev-parse --abbrev-ref --symbolic-full-name "@{u}" 2>/dev/null)" || return 1
  case "$upstream" in
    */*) resolve_remote_json "${upstream%%/*}" "branch_upstream" ;;
    *) return 1 ;;
  esac
}

resolve_from_known_remotes_json() {
  resolve_from_upstream_json && return 0
  resolve_remote_json origin "origin" && return 0
  resolve_remote_json upstream "upstream" && return 0
  return 1
}

resolve_all_remotes_json() {
  results_file="$(mktemp)"
  trap 'rm -f "$results_file"' EXIT HUP INT TERM

  seen_keys="|"
  found=0

  for remote_name in $(git remote); do
    if target_json="$(resolve_remote_json "$remote_name" "all_remotes")"; then
      key="$(printf '%s\n' "$target_json" | jq -r '.host + "/" + .repo')"
      case "$seen_keys" in
        *"|$key|"*) continue ;;
      esac
      seen_keys="$seen_keys$key|"
      printf '%s\n' "$target_json" >>"$results_file"
      found=1
    fi
  done

  if [ "$found" -eq 0 ]; then
    die "Could not resolve any GitHub or GitLab repositories from remotes" 2
  fi

  jq -s '{host: "mixed", repo: null, source: "all_remotes", targets: .}' "$results_file"
}

host=""
repo=""
remote=""
target=""
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
      die "Use 'all remotes' or --all-remotes for multi-remote resolution" 2
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

require_command jq

case "$host" in
  ""|github|gitlab) ;;
  *) die "Unsupported --host value: $host" 2 ;;
esac

if [ -n "$remote" ] && [ -n "$target" ]; then
  die "Use either --remote or a positional remote/URL target, not both" 2
fi

if [ "$all_remotes" -eq 1 ]; then
  if [ -n "$remote" ] || [ -n "$target" ] || [ -n "$repo" ]; then
    die "Use all-remotes resolution without --repo, --remote, or a positional target" 2
  fi
  require_command git
  resolve_all_remotes_json
  exit 0
fi

if [ -n "$remote" ]; then
  require_command git
  resolve_remote_json "$remote" "remote" || die "Could not resolve GitHub or GitLab repository from remote: $remote" 2
elif [ -n "$target" ]; then
  require_command git
  resolve_target_json "$target" || die "Could not resolve GitHub or GitLab repository from target: $target" 2
elif [ -n "$repo" ]; then
  if [ -z "$host" ]; then
    host="github"
  fi
  json_target "$host" "$repo" "explicit" "" ""
else
  require_command git
  resolve_from_known_remotes_json || die "Could not resolve GitHub or GitLab repository from branch upstream, origin, or upstream" 2
fi
