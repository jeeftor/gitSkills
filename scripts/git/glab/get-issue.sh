#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab/get-issue.sh --repo group/project --issue n [--comment-limit n]

Collect one GitLab issue as normalized JSON for gitSkills detail workflows.
The script is read-only and uses glab for repository access.
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
comment_limit="100"

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
    --comment-limit)
      comment_limit="${2:?missing value for --comment-limit}"
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

case "$comment_limit" in
  ''|*[!0-9]*)
    die "--comment-limit must be a positive integer" 2
    ;;
  *)
    if [ "$comment_limit" -eq 0 ]; then
      die "--comment-limit must be a positive integer" 2
    fi
    ;;
esac

require_command glab
require_command jq

project_path="$(printf '%s' "$repo" | jq -sRr @uri)"

issue_file="$(mktemp)"
comments_file="$(mktemp)"
trap 'rm -f "$issue_file" "$comments_file"' EXIT HUP INT TERM

glab api "projects/$project_path/issues/$issue" >"$issue_file"
glab api "projects/$project_path/issues/$issue/notes?per_page=$comment_limit" >"$comments_file"

jq \
  --arg host "gitlab" \
  --arg repo "$repo" \
  --slurpfile comments "$comments_file" \
  '
  {
    host: $host,
    repo: $repo,
    issue: {
      number: .iid,
      title,
      url: .web_url,
      state,
      author: (.author.username // null),
      assignees: [(.assignees // [])[].username],
      labels: (.labels // []),
      milestone: (.milestone.title // null),
      body: (.description // ""),
      comments_count: (($comments[0] // []) | length),
      comments: [
        ($comments[0] // [])[] |
        {
          author: (.author.username // null),
          body: (.body // ""),
          url: null,
          created_at,
          updated_at,
          system: (.system // false),
          internal: (.internal // false)
        }
      ],
      created_at,
      updated_at,
      closed_at,
      issue_type,
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
      },
      table: {
        display: ("#" + (.iid | tostring)),
        labels_text: (if ((.labels // []) | length) == 0 then "No labels" else ((.labels // []) | join(", ")) end),
        assignee_text: (if ((.assignees // []) | length) == 0 then "No assignee" else ([(.assignees // [])[].username] | join(", ")) end),
        updated_at
      }
    }
  }' \
  "$issue_file"
