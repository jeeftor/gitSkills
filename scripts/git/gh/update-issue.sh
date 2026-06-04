#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh/update-issue.sh --repo owner/name --issue n [mutation flags] [--yes]

Update one GitHub issue. Without --yes, emit a dry-run JSON plan.
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

append_json_array() {
  file="$1"
  value="$2"
  jq --arg value "$value" '. + [$value]' "$file" >"$file.tmp"
  mv "$file.tmp" "$file"
}

repo=""
issue=""
title=""
body=""
body_file=""
comment=""
comment_file=""
milestone=""
clear_milestone=0
close_issue=0
reopen_issue=0
assume_yes=0

labels_add_file="$(mktemp)"
labels_remove_file="$(mktemp)"
assignees_add_file="$(mktemp)"
assignees_remove_file="$(mktemp)"
printf '[]\n' >"$labels_add_file"
printf '[]\n' >"$labels_remove_file"
printf '[]\n' >"$assignees_add_file"
printf '[]\n' >"$assignees_remove_file"
trap 'rm -f "$labels_add_file" "$labels_remove_file" "$assignees_add_file" "$assignees_remove_file"' EXIT HUP INT TERM

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo) repo="${2:?missing value for --repo}"; shift 2 ;;
    --issue) issue="${2:?missing value for --issue}"; shift 2 ;;
    --title) title="${2:?missing value for --title}"; shift 2 ;;
    --body) body="${2:?missing value for --body}"; shift 2 ;;
    --body-file) body_file="${2:?missing value for --body-file}"; shift 2 ;;
    --comment) comment="${2:?missing value for --comment}"; shift 2 ;;
    --comment-file) comment_file="${2:?missing value for --comment-file}"; shift 2 ;;
    --add-label) append_json_array "$labels_add_file" "${2:?missing value for --add-label}"; shift 2 ;;
    --remove-label) append_json_array "$labels_remove_file" "${2:?missing value for --remove-label}"; shift 2 ;;
    --add-assignee) append_json_array "$assignees_add_file" "${2:?missing value for --add-assignee}"; shift 2 ;;
    --remove-assignee) append_json_array "$assignees_remove_file" "${2:?missing value for --remove-assignee}"; shift 2 ;;
    --milestone) milestone="${2:?missing value for --milestone}"; shift 2 ;;
    --clear-milestone) clear_milestone=1; shift ;;
    --close) close_issue=1; shift ;;
    --reopen) reopen_issue=1; shift ;;
    --yes) assume_yes=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) die "Unknown argument: $1" 2 ;;
  esac
done

[ -n "$repo" ] || die "--repo is required" 2
case "$issue" in ''|*[!0-9]*) die "--issue must be an issue number" 2 ;; esac
[ -z "$body" ] || [ -z "$body_file" ] || die "Use either --body or --body-file, not both" 2
[ -z "$comment" ] || [ -z "$comment_file" ] || die "Use either --comment or --comment-file, not both" 2
[ "$close_issue" -eq 0 ] || [ "$reopen_issue" -eq 0 ] || die "Use either --close or --reopen, not both" 2
[ -z "$milestone" ] || [ "$clear_milestone" -eq 0 ] || die "Use either --milestone or --clear-milestone, not both" 2

before_file="$(mktemp)"
after_file="$(mktemp)"
body_value_file="$(mktemp)"
comment_value_file="$(mktemp)"
labels_add_lines="$(mktemp)"
labels_remove_lines="$(mktemp)"
assignees_add_lines="$(mktemp)"
assignees_remove_lines="$(mktemp)"
trap 'rm -f "$labels_add_file" "$labels_remove_file" "$assignees_add_file" "$assignees_remove_file" "$before_file" "$after_file" "$body_value_file" "$comment_value_file" "$labels_add_lines" "$labels_remove_lines" "$assignees_add_lines" "$assignees_remove_lines"' EXIT HUP INT TERM

"$(script_dir)/get-issue.sh" --repo "$repo" --issue "$issue" >"$before_file"

if [ -n "$body_file" ]; then
  cat "$body_file" >"$body_value_file"
elif [ -n "$body" ]; then
  printf '%s' "$body" >"$body_value_file"
fi

if [ -n "$comment_file" ]; then
  cat "$comment_file" >"$comment_value_file"
elif [ -n "$comment" ]; then
  printf '%s' "$comment" >"$comment_value_file"
fi

if [ "$assume_yes" -eq 1 ]; then
  if [ -n "$title" ] || [ -s "$body_value_file" ] || [ -n "$milestone" ] || [ "$clear_milestone" -eq 1 ] ||
     [ "$(jq 'length' "$labels_add_file")" -gt 0 ] || [ "$(jq 'length' "$labels_remove_file")" -gt 0 ] ||
     [ "$(jq 'length' "$assignees_add_file")" -gt 0 ] || [ "$(jq 'length' "$assignees_remove_file")" -gt 0 ]; then
    set -- gh issue edit "$issue" --repo "$repo"
    [ -z "$title" ] || set -- "$@" --title "$title"
    [ ! -s "$body_value_file" ] || set -- "$@" --body-file "$body_value_file"
    [ -z "$milestone" ] || set -- "$@" --milestone "$milestone"
    [ "$clear_milestone" -eq 0 ] || set -- "$@" --remove-milestone
    jq -r '.[]' "$labels_add_file" >"$labels_add_lines"
    while IFS= read -r label; do set -- "$@" --add-label "$label"; done <"$labels_add_lines"
    jq -r '.[]' "$labels_remove_file" >"$labels_remove_lines"
    while IFS= read -r label; do set -- "$@" --remove-label "$label"; done <"$labels_remove_lines"
    jq -r '.[]' "$assignees_add_file" >"$assignees_add_lines"
    while IFS= read -r user; do set -- "$@" --add-assignee "$user"; done <"$assignees_add_lines"
    jq -r '.[]' "$assignees_remove_file" >"$assignees_remove_lines"
    while IFS= read -r user; do set -- "$@" --remove-assignee "$user"; done <"$assignees_remove_lines"
    "$@"
  fi
  [ ! -s "$comment_value_file" ] || gh issue comment "$issue" --repo "$repo" --body-file "$comment_value_file"
  [ "$close_issue" -eq 0 ] || gh issue close "$issue" --repo "$repo"
  [ "$reopen_issue" -eq 0 ] || gh issue reopen "$issue" --repo "$repo"
  "$(script_dir)/get-issue.sh" --repo "$repo" --issue "$issue" >"$after_file"
else
  printf 'null\n' >"$after_file"
fi

jq -n \
  --slurpfile before "$before_file" \
  --slurpfile after "$after_file" \
  --slurpfile add_labels "$labels_add_file" \
  --slurpfile remove_labels "$labels_remove_file" \
  --slurpfile add_assignees "$assignees_add_file" \
  --slurpfile remove_assignees "$assignees_remove_file" \
  --arg title "$title" \
  --arg body "$(cat "$body_value_file")" \
  --arg comment "$(cat "$comment_value_file")" \
  --arg milestone "$milestone" \
  --argjson clear_milestone "$clear_milestone" \
  --argjson close "$close_issue" \
  --argjson reopen "$reopen_issue" \
  --argjson yes "$assume_yes" '
  {
    host: "github",
    repo: $before[0].repo,
    issue: $before[0].issue.number,
    dry_run: ($yes == 0),
    mutated: ($yes == 1),
    before: $before[0].issue,
    action: {
      title: (if $title == "" then null else $title end),
      body: (if $body == "" then null else $body end),
      comment: (if $comment == "" then null else $comment end),
      add_labels: $add_labels[0],
      remove_labels: $remove_labels[0],
      add_assignees: $add_assignees[0],
      remove_assignees: $remove_assignees[0],
      milestone: (if $milestone == "" then null else $milestone end),
      clear_milestone: ($clear_milestone == 1),
      close: ($close == 1),
      reopen: ($reopen == 1)
    },
    after: (if $yes == 1 then $after[0].issue else null end)
  }'
