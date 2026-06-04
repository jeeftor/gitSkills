#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab/update-issue.sh --repo group/project --issue n [--comment text|--comment-file file] [--title title] [--body text|--body-file file] [--add-label name] [--remove-label name] [--add-assignee username] [--remove-assignee username] [--milestone title|--clear-milestone] [--close|--reopen] [--yes]

Update one GitLab issue. Without --yes, emit before/action JSON without mutating.
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

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
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

repo=""
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
mutation_count=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --issue)
      issue="${2:?missing value for --issue}"
      shift 2
      ;;
    --comment)
      comment="${2:?missing value for --comment}"
      comment_set="1"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --comment-file)
      comment_file="${2:?missing value for --comment-file}"
      comment_set="1"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --title)
      title="${2:?missing value for --title}"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --body)
      body="${2:?missing value for --body}"
      body_set="1"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --body-file)
      body_file="${2:?missing value for --body-file}"
      body_set="1"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --add-label)
      printf '%s\n' "${2:?missing value for --add-label}" >>"$add_labels_file"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --remove-label)
      printf '%s\n' "${2:?missing value for --remove-label}" >>"$remove_labels_file"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --add-assignee)
      printf '%s\n' "${2:?missing value for --add-assignee}" >>"$add_assignees_file"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --remove-assignee)
      printf '%s\n' "${2:?missing value for --remove-assignee}" >>"$remove_assignees_file"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --milestone)
      milestone="${2:?missing value for --milestone}"
      mutation_count=$((mutation_count + 1))
      shift 2
      ;;
    --clear-milestone)
      clear_milestone="1"
      mutation_count=$((mutation_count + 1))
      shift
      ;;
    --close)
      close_issue="1"
      mutation_count=$((mutation_count + 1))
      shift
      ;;
    --reopen)
      reopen_issue="1"
      mutation_count=$((mutation_count + 1))
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
    *)
      die "Unknown argument: $1" 2
      ;;
  esac
done

[ -n "$repo" ] || die "--repo is required" 2

case "$issue" in
  ''|*[!0-9]*)
    die "--issue must be an issue number" 2
    ;;
esac

[ "$mutation_count" -gt 0 ] || die "At least one update action is required" 2

if [ -n "$comment" ] && [ -n "$comment_file" ]; then
  die "Use either --comment or --comment-file, not both" 2
fi

if [ -n "$body" ] && [ -n "$body_file" ]; then
  die "Use either --body or --body-file, not both" 2
fi

if [ "$close_issue" = "1" ] && [ "$reopen_issue" = "1" ]; then
  die "Use either --close or --reopen, not both" 2
fi

if [ -n "$milestone" ] && [ "$clear_milestone" = "1" ]; then
  die "Use either --milestone or --clear-milestone, not both" 2
fi

require_command glab
require_command jq

prepared_comment_file="$tmp_dir/comment"
prepared_body_file="$tmp_dir/body"
comment_source="none"
body_source="none"

if [ -n "$comment_file" ]; then
  [ -f "$comment_file" ] || die "Comment file does not exist: $comment_file" 2
  prepared_comment_file="$comment_file"
  comment_source="file"
elif [ "$comment_set" = "1" ]; then
  printf '%s\n' "$comment" >"$prepared_comment_file"
  comment_source="inline"
else
  : >"$prepared_comment_file"
fi

if [ -n "$body_file" ]; then
  [ -f "$body_file" ] || die "Body file does not exist: $body_file" 2
  prepared_body_file="$body_file"
  body_source="file"
elif [ "$body_set" = "1" ]; then
  printf '%s\n' "$body" >"$prepared_body_file"
  body_source="inline"
else
  : >"$prepared_body_file"
fi

before_file="$tmp_dir/before.json"
"$(script_dir)/get-issue.sh" --repo "$repo" --issue "$issue" >"$before_file"

emit_json() {
  after_file="$1"
  dry_run_value="$2"
  mutated_value="$3"

  jq -n \
    --arg host "gitlab" \
    --arg repo "$repo" \
    --argjson issue "$issue" \
    --argjson dry_run "$dry_run_value" \
    --argjson mutated "$mutated_value" \
    --arg title "$title" \
    --arg comment_source "$comment_source" \
    --arg body_source "$body_source" \
    --arg body_set "$body_set" \
    --arg comment_set "$comment_set" \
    --arg milestone "$milestone" \
    --arg clear_milestone "$clear_milestone" \
    --arg close "$close_issue" \
    --arg reopen "$reopen_issue" \
    --rawfile comment "$prepared_comment_file" \
    --rawfile body "$prepared_body_file" \
    --rawfile add_labels "$add_labels_file" \
    --rawfile remove_labels "$remove_labels_file" \
    --rawfile add_assignees "$add_assignees_file" \
    --rawfile remove_assignees "$remove_assignees_file" \
    --slurpfile before "$before_file" \
    --slurpfile after "$after_file" \
    '
    def lines($value):
      if $value == "" then [] else ($value | split("\n") | map(select(length > 0))) end;

    {
      host: $host,
      repo: $repo,
      issue: $issue,
      dry_run: $dry_run,
      mutated: $mutated,
      before: $before[0].issue,
      action: {
        comment: (if $comment_set == "1" then {body: $comment, source: $comment_source} else null end),
        title: (if $title == "" then null else $title end),
        body: (if $body_set == "1" then {body: $body, source: $body_source} else null end),
        add_labels: lines($add_labels),
        remove_labels: lines($remove_labels),
        add_assignees: lines($add_assignees),
        remove_assignees: lines($remove_assignees),
        milestone: (if $milestone == "" then null else $milestone end),
        clear_milestone: ($clear_milestone == "1"),
        close: ($close == "1"),
        reopen: ($reopen == "1")
      },
      after: (if $mutated then $after[0].issue else null end),
      message: (if $dry_run then "Pass --yes to update the issue after explicit user intent is confirmed." else "Issue update applied." end)
    }'
}

if [ "$assume_yes" != "1" ]; then
  empty_after="$tmp_dir/after-empty.json"
  printf '%s\n' '{}' >"$empty_after"
  emit_json "$empty_after" true false
  exit 0
fi

edit_needed="0"
set -- glab issue update "$issue" --repo "$repo"

if [ -n "$title" ]; then
  set -- "$@" --title "$title"
  edit_needed="1"
fi
if [ "$body_set" = "1" ]; then
  set -- "$@" --description "$(cat "$prepared_body_file")"
  edit_needed="1"
fi
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --label "$value"
  edit_needed="1"
done <"$add_labels_file"
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --unlabel "$value"
  edit_needed="1"
done <"$remove_labels_file"
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --assignee "+$value"
  edit_needed="1"
done <"$add_assignees_file"
while IFS= read -r value; do
  [ -n "$value" ] || continue
  set -- "$@" --assignee "-$value"
  edit_needed="1"
done <"$remove_assignees_file"
if [ -n "$milestone" ]; then
  set -- "$@" --milestone "$milestone"
  edit_needed="1"
elif [ "$clear_milestone" = "1" ]; then
  set -- "$@" --milestone ""
  edit_needed="1"
fi

if [ "$edit_needed" = "1" ]; then
  "$@" >/dev/null
fi

if [ "$comment_set" = "1" ]; then
  glab issue note "$issue" --repo "$repo" --message "$(cat "$prepared_comment_file")" >/dev/null
fi

if [ "$close_issue" = "1" ]; then
  glab issue close "$issue" --repo "$repo" >/dev/null
elif [ "$reopen_issue" = "1" ]; then
  glab issue reopen "$issue" --repo "$repo" >/dev/null
fi

after_file="$tmp_dir/after.json"
"$(script_dir)/get-issue.sh" --repo "$repo" --issue "$issue" >"$after_file"
emit_json "$after_file" false true
