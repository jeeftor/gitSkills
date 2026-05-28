#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab/get-mr.sh --repo group/project [--number iid|--branch branch]

Collect one GitLab merge request as normalized JSON for gitSkills watcher workflows.
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

number_value() {
  value="$1"
  value="${value#!}"
  case "$value" in
    ''|*[!0-9]*) return 1 ;;
    *) printf '%s\n' "$value" ;;
  esac
}

repo=""
number=""
branch=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --number)
      number="$(number_value "${2:?missing value for --number}")" || die "--number must be a merge request IID" 2
      shift 2
      ;;
    --branch)
      branch="${2:?missing value for --branch}"
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

if [ -n "$number" ] && [ -n "$branch" ]; then
  die "Use either --number or --branch, not both" 2
fi

require_command glab
require_command jq

project_path="$(printf '%s' "$repo" | jq -sRr @uri)"

if [ -z "$number" ]; then
  if [ -z "$branch" ]; then
    branch="$(git branch --show-current 2>/dev/null || true)"
  fi
  [ -n "$branch" ] || die "--number or --branch is required when the current branch cannot be detected" 2

  branch_query="$(printf '%s' "$branch" | jq -sRr @uri)"
  matches_file="$(mktemp)"
  trap 'rm -f "$matches_file"' EXIT HUP INT TERM
  glab api "projects/$project_path/merge_requests?source_branch=$branch_query&state=all&per_page=2" >"$matches_file"
  match_count="$(jq 'length' "$matches_file")"
  case "$match_count" in
    0) die "Could not find a GitLab merge request for branch: $branch" 2 ;;
    1) number="$(jq -r '.[0].iid' "$matches_file")" ;;
    *) die "More than one GitLab merge request matched branch: $branch" 2 ;;
  esac
fi

mr_file="$(mktemp)"
discussions_file="$(mktemp)"
approvals_file="$(mktemp)"
trap 'rm -f "${matches_file:-}" "$mr_file" "$discussions_file" "$approvals_file"' EXIT HUP INT TERM

glab api "projects/$project_path/merge_requests/$number" >"$mr_file"
if ! glab api "projects/$project_path/merge_requests/$number/discussions" >"$discussions_file" 2>/dev/null; then
  printf '[]\n' >"$discussions_file"
fi
if ! glab api "projects/$project_path/merge_requests/$number/approvals" >"$approvals_file" 2>/dev/null; then
  printf '{}\n' >"$approvals_file"
fi

jq -n \
  --arg host "gitlab" \
  --arg repo "$repo" \
  --slurpfile mr "$mr_file" \
  --slurpfile discussions "$discussions_file" \
  --slurpfile approvals "$approvals_file" '
  ($mr[0]) as $item |
  ($discussions[0] // []) as $discussion_items |
  ($approvals[0] // {}) as $approval_data |
  {
    host: $host,
    repo: $repo,
    kind: "mr",
    number: $item.iid,
    title: $item.title,
    url: $item.web_url,
    state: $item.state,
    is_draft: ($item.draft // $item.work_in_progress // false),
    author: ($item.author.username // null),
    assignees: [($item.assignees // [])[].username],
    reviewers: [($item.reviewers // [])[].username],
    labels: ($item.labels // []),
    body: ($item.description // ""),
    created_at: $item.created_at,
    updated_at: $item.updated_at,
    closed_at: $item.closed_at,
    merged_at: $item.merged_at,
    head_branch: $item.source_branch,
    base_branch: $item.target_branch,
    head_sha: ($item.sha // null),
    merge_status: ($item.merge_status // "unknown"),
    detailed_merge_status: ($item.detailed_merge_status // "unknown"),
    has_conflicts: ($item.has_conflicts // null),
    blocking_discussions_resolved: ($item.blocking_discussions_resolved // null),
    approvals: {
      approved: ($approval_data.approved // null),
      approvals_required: ($approval_data.approvals_required // null),
      approvals_left: ($approval_data.approvals_left // null),
      approved_by: [($approval_data.approved_by // [])[] | .user.username]
    },
    discussions: [
      $discussion_items[] | {
        id,
        individual_note: (.individual_note // false),
        resolved: (.resolved // null),
        notes: [
          (.notes // [])[] | {
            author: (.author.username // null),
            system: (.system // false),
            resolvable: (.resolvable // false),
            resolved: (.resolved // null),
            created_at,
            updated_at,
            body: (.body // "")
          }
        ]
      }
    ],
    unresolved_discussions: ([
      $discussion_items[] |
      select((.resolved // true) == false)
    ] | length),
    pipeline: {
      id: ($item.head_pipeline.id // null),
      status: ($item.head_pipeline.status // null),
      url: ($item.head_pipeline.web_url // null)
    }
  }'
