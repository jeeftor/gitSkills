#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab-get-mrs.sh --repo group/project [--state open|opened|closed|merged|all] [--scope all|authored|assigned|review] [--limit n]

Collect GitLab merge requests as normalized JSON for gitSkills table workflows.
The script is read-only and uses glab for repository access.
EOF
}

repo=""
state="opened"
scope="all"
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
    --scope)
      scope="${2:?missing value for --scope}"
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
  merged) api_state="merged" ;;
  all) api_state="all" ;;
  *)
    echo "Unsupported --state value: $state" >&2
    exit 2
    ;;
esac

case "$scope" in
  all|authored|assigned|review) ;;
  *)
    echo "Unsupported --scope value: $scope" >&2
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
  echo "--repo is required for GitLab merge request collection" >&2
  exit 2
fi

for command_name in glab jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 127
  fi
done

project_path="$(printf '%s' "$repo" | jq -sRr @uri)"
api_query="state=$api_state&per_page=$limit"

case "$scope" in
  authored|assigned|review)
    user_file="$(mktemp)"
    trap 'rm -f "$user_file"' EXIT HUP INT TERM
    glab api user >"$user_file"
    username="$(jq -r .username "$user_file")"
    username_query="$(printf '%s' "$username" | jq -sRr @uri)"
    case "$scope" in
      authored)
        api_query="$api_query&author_username=$username_query"
        ;;
      assigned)
        api_query="$api_query&assignee_username=$username_query"
        ;;
      review)
        api_query="$api_query&reviewer_username=$username_query"
        ;;
    esac
    ;;
esac

mrs_file="$(mktemp)"
trap 'rm -f "${user_file:-}" "$mrs_file"' EXIT HUP INT TERM

glab api "projects/$project_path/merge_requests?$api_query" >"$mrs_file"

jq \
    --arg host "gitlab" \
    --arg repo "$repo" \
    --arg state "$api_state" \
    --arg scope "$scope" \
    --argjson limit "$limit" \
    '{
      host: $host,
      repo: $repo,
      state: $state,
      scope: $scope,
      limit: $limit,
      merge_requests: [
        .[] | {
          number: .iid,
          title,
          url: .web_url,
          state,
          is_draft: (.draft // .work_in_progress // false),
          labels: (.labels // []),
          assignees: [(.assignees // [])[].username],
          reviewers: [(.reviewers // [])[].username],
          author: (.author.username // null),
          updated_at,
          head_branch: .source_branch,
          base_branch: .target_branch,
          merge_status: (.merge_status // "unknown"),
          detailed_merge_status: (.detailed_merge_status // "unknown"),
          has_conflicts: (.has_conflicts // null),
          blocking_discussions_resolved: (.blocking_discussions_resolved // null),
          pipeline: {
            id: (.head_pipeline.id // null),
            status: (.head_pipeline.status // null),
            url: (.head_pipeline.web_url // null)
          }
        }
      ]
    }' \
    "$mrs_file"
