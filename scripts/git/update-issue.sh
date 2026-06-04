#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/update-issue.sh [remote-or-url] [issue-number-or-url] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--issue n] [--comment text|--comment-file file] [--title title] [--body text|--body-file file] [--add-label name] [--remove-label name] [--add-assignee login] [--remove-assignee login] [--milestone title|--clear-milestone] [--close|--reopen] [--yes]

Resolve one GitHub or GitLab issue and delegate an explicit issue update to the provider helper.
Without --yes, provider helpers emit before/action JSON without mutating.
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

tmp_dir="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

add_labels_file="$tmp_dir/add-labels"
remove_labels_file="$tmp_dir/remove-labels"
add_assignees_file="$tmp_dir/add-assignees"
remove_assignees_file="$tmp_dir/remove-assignees"
: >"$add_labels_file"
: >"$remove_labels_file"
: >"$add_assignees_file"
: >"$remove_assignees_file"

host=""
repo=""
remote=""
target=""
issue=""
comment=""
comment_file=""
title=""
body=""
body_file=""
milestone=""
clear_milestone="0"
close_issue="0"
reopen_issue="0"
assume_yes="0"
body_set="0"
comment_set="0"

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
    --comment)
      comment="${2:?missing value for --comment}"
      comment_set="1"
      shift 2
      ;;
    --comment-file)
      comment_file="${2:?missing value for --comment-file}"
      comment_set="1"
      shift 2
      ;;
    --title)
      title="${2:?missing value for --title}"
      shift 2
      ;;
    --body)
      body="${2:?missing value for --body}"
      body_set="1"
      shift 2
      ;;
    --body-file)
      body_file="${2:?missing value for --body-file}"
      body_set="1"
      shift 2
      ;;
    --add-label)
      printf '%s\n' "${2:?missing value for --add-label}" >>"$add_labels_file"
      shift 2
      ;;
    --remove-label)
      printf '%s\n' "${2:?missing value for --remove-label}" >>"$remove_labels_file"
      shift 2
      ;;
    --add-assignee)
      printf '%s\n' "${2:?missing value for --add-assignee}" >>"$add_assignees_file"
      shift 2
      ;;
    --remove-assignee)
      printf '%s\n' "${2:?missing value for --remove-assignee}" >>"$remove_assignees_file"
      shift 2
      ;;
    --milestone)
      milestone="${2:?missing value for --milestone}"
      shift 2
      ;;
    --clear-milestone)
      clear_milestone="1"
      shift
      ;;
    --close)
      close_issue="1"
      shift
      ;;
    --reopen)
      reopen_issue="1"
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

set -- --repo "$repo" --issue "$issue"

if [ "$comment_set" = "1" ]; then
  if [ -n "$comment_file" ]; then
    set -- "$@" --comment-file "$comment_file"
  else
    set -- "$@" --comment "$comment"
  fi
fi
if [ -n "$title" ]; then
  set -- "$@" --title "$title"
fi
if [ "$body_set" = "1" ]; then
  if [ -n "$body_file" ]; then
    set -- "$@" --body-file "$body_file"
  else
    set -- "$@" --body "$body"
  fi
fi
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --add-label "$value"
done <"$add_labels_file"
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --remove-label "$value"
done <"$remove_labels_file"
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --add-assignee "$value"
done <"$add_assignees_file"
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --remove-assignee "$value"
done <"$remove_assignees_file"
if [ -n "$milestone" ]; then
  set -- "$@" --milestone "$milestone"
elif [ "$clear_milestone" = "1" ]; then
  set -- "$@" --clear-milestone
fi
if [ "$close_issue" = "1" ]; then
  set -- "$@" --close
fi
if [ "$reopen_issue" = "1" ]; then
  set -- "$@" --reopen
fi
if [ "$assume_yes" = "1" ]; then
  set -- "$@" --yes
fi

case "$host" in
  github)
    exec "$(script_dir)/gh/update-issue.sh" "$@"
    ;;
  gitlab)
    exec "$(script_dir)/glab/update-issue.sh" "$@"
    ;;
  *)
    die "Could not determine issue host. Use --host github or --host gitlab." 2
    ;;
esac
