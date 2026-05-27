#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh-get-issues.sh [--repo owner/name] [--state open|closed|all] [--limit n]

Collect GitHub issues as normalized JSON for gitSkills table workflows.
The script is read-only and uses gh for repository access.
EOF
}

repo=""
state="open"
limit="50"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:?missing value for --repo}"
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
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$state" in
  open|closed|all) ;;
  *)
    echo "Unsupported --state value: $state" >&2
    exit 2
    ;;
esac

case "$limit" in
  ''|*[!0-9]*)
    echo "--limit must be a positive integer" >&2
    exit 2
    ;;
  *)
    if [ "$limit" -eq 0 ]; then
      echo "--limit must be a positive integer" >&2
      exit 2
    fi
    ;;
esac

for command_name in gh jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 127
  fi
done

if [ -z "$repo" ]; then
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi

items_file="$(mktemp)"
numbers_file="$(mktemp)"
details_file="$(mktemp)"
trap 'rm -f "$items_file" "$numbers_file" "$details_file"' EXIT HUP INT TERM

: >"$items_file"

gh issue list \
  --repo "$repo" \
  --state "$state" \
  --limit "$limit" \
  --json number >"$numbers_file"

jq -r '.[].number' "$numbers_file" |
  while IFS= read -r number; do
    gh api "repos/$repo/issues/$number" >"$details_file"
    jq -c '{
        number,
        title,
        url: .html_url,
        state,
        labels: [.labels[].name],
        assignees: [.assignees[].login],
        author: .user.login,
        updated_at,
        parent_issue_url: (.parent_issue_url // null),
        parent_issue_number: (try (.parent_issue_url | capture("/issues/(?<number>[0-9]+)$").number | tonumber) catch null),
        sub_issues: (.sub_issues_summary // {total: 0, completed: 0, percent_completed: 0}),
        dependencies: (.issue_dependencies_summary // {blocked_by: 0, total_blocked_by: 0, blocking: 0, total_blocking: 0})
      }' "$details_file" >>"$items_file"
  done

jq -s \
  --arg host "github" \
  --arg repo "$repo" \
  --arg state "$state" \
  --argjson limit "$limit" \
  '{host: $host, repo: $repo, state: $state, limit: $limit, issues: .}' \
  "$items_file"
