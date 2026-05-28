#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh/get-issue.sh --repo owner/name --issue n

Collect one GitHub issue as normalized JSON for gitSkills detail workflows.
The script is read-only and uses gh for repository access.
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

repo=""
issue=""

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

require_command gh
require_command jq

issue_file="$(mktemp)"
trap 'rm -f "$issue_file"' EXIT HUP INT TERM

gh issue view "$issue" \
  --repo "$repo" \
  --comments \
  --json number,title,url,state,author,assignees,labels,milestone,body,comments,createdAt,updatedAt,closedAt >"$issue_file"

jq \
  --arg host "github" \
  --arg repo "$repo" \
  '
  {
    host: $host,
    repo: $repo,
    issue: {
      number,
      title,
      url,
      state,
      author: (.author.login // null),
      assignees: [(.assignees // [])[].login],
      labels: [(.labels // [])[].name],
      milestone: (.milestone.title // null),
      body: (.body // ""),
      comments_count: ((.comments // []) | length),
      comments: [
        (.comments // [])[] |
        {
          author: (.author.login // null),
          body: (.body // ""),
          url: (.url // null),
          created_at: .createdAt,
          updated_at: .updatedAt
        }
      ],
      created_at: .createdAt,
      updated_at: .updatedAt,
      closed_at: .closedAt,
      table: {
        display: ("#" + (.number | tostring)),
        labels_text: (if ((.labels // []) | length) == 0 then "No labels" else ([.labels[].name] | join(", ")) end),
        assignee_text: (if ((.assignees // []) | length) == 0 then "No assignee" else ([.assignees[].login] | join(", ")) end),
        updated_at: .updatedAt
      }
    }
  }' \
  "$issue_file"
