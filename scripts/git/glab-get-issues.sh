#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab-get-issues.sh --repo group/project [--state open|opened|closed|all] [--limit n]

Collect GitLab issues as normalized JSON for gitSkills table workflows.
The script is read-only and uses glab for repository access.
EOF
}

repo=""
state="opened"
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
  open|opened) api_state="opened" ;;
  closed) api_state="closed" ;;
  all) api_state="all" ;;
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

if [ -z "$repo" ]; then
  echo "--repo is required for GitLab issue collection" >&2
  exit 2
fi

for command_name in glab jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 127
  fi
done

project_path="$(printf '%s' "$repo" | jq -sRr @uri)"

issues_file="$(mktemp)"
trap 'rm -f "$issues_file"' EXIT HUP INT TERM

glab api "projects/$project_path/issues?state=$api_state&per_page=$limit" >"$issues_file"

jq \
    --arg host "gitlab" \
    --arg repo "$repo" \
    --arg state "$api_state" \
    --argjson limit "$limit" \
    '{
      host: $host,
      repo: $repo,
      state: $state,
      limit: $limit,
      issues: [
        .[] | {
          number: .iid,
          title,
          url: .web_url,
          state,
          labels: (.labels // []),
          assignees: [(.assignees // [])[].username],
          author: .author.username,
          updated_at,
          issue_type,
          parent_issue_url: null,
          parent_issue_number: null,
          sub_issues: {
            total: (.task_completion_status.count // 0),
            completed: (.task_completion_status.completed_count // 0),
            percent_completed: (
              if (.task_completion_status.count // 0) > 0 then
                (((.task_completion_status.completed_count // 0) * 100) / .task_completion_status.count | floor)
              else
                0
              end
            )
          },
          dependencies: {
            blocked_by: null,
            total_blocked_by: null,
            blocking: (.blocking_issues_count // 0),
            total_blocking: (.blocking_issues_count // 0)
          }
        }
      ]
    }' \
    "$issues_file"
