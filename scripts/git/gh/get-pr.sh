#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh/get-pr.sh --repo owner/name [--number n|--branch branch]

Collect one GitHub pull request as normalized JSON for gitSkills watcher workflows.
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

number_value() {
  value="$1"
  value="${value#\#}"
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
      number="$(number_value "${2:?missing value for --number}")" || die "--number must be a pull request number" 2
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

require_command gh
require_command jq

if [ -z "$number" ]; then
  if [ -z "$branch" ]; then
    branch="$(git branch --show-current 2>/dev/null || true)"
  fi
  [ -n "$branch" ] || die "--number or --branch is required when the current branch cannot be detected" 2

  matches_file="$(mktemp)"
  trap 'rm -f "$matches_file"' EXIT HUP INT TERM
  gh pr list --repo "$repo" --head "$branch" --state all --limit 2 --json number >"$matches_file"
  match_count="$(jq 'length' "$matches_file")"
  case "$match_count" in
    0) die "Could not find a GitHub pull request for branch: $branch" 2 ;;
    1) number="$(jq -r '.[0].number' "$matches_file")" ;;
    *) die "More than one GitHub pull request matched branch: $branch" 2 ;;
  esac
fi

pr_file="$(mktemp)"
trap 'rm -f "${matches_file:-}" "$pr_file"' EXIT HUP INT TERM

gh pr view "$number" \
  --repo "$repo" \
  --json number,title,url,state,isDraft,mergeStateStatus,reviewDecision,reviews,latestReviews,comments,statusCheckRollup,updatedAt,createdAt,closedAt,mergedAt,headRefName,baseRefName,headRefOid,author,assignees,labels,reviewRequests,body \
  >"$pr_file"

jq \
  --arg host "github" \
  --arg repo "$repo" '
  (.statusCheckRollup // []) as $checks |
  {
    host: $host,
    repo: $repo,
    kind: "pr",
    number,
    title,
    url,
    state,
    is_draft: (.isDraft // false),
    author: (.author.login // null),
    assignees: [(.assignees // [])[].login],
    labels: [(.labels // [])[].name],
    review_requests: [(.reviewRequests // [])[] | (.login // .slug // .name // empty)],
    body: (.body // ""),
    created_at: .createdAt,
    updated_at: .updatedAt,
    closed_at: .closedAt,
    merged_at: .mergedAt,
    head_branch: .headRefName,
    base_branch: .baseRefName,
    head_sha: .headRefOid,
    review_decision: (.reviewDecision // "UNKNOWN"),
    merge_state_status: (.mergeStateStatus // "UNKNOWN"),
    reviews: [
      (.reviews // [])[] | {
        author: (.author.login // null),
        state,
        submitted_at: .submittedAt,
        body: (.body // "")
      }
    ],
    latest_reviews: [
      (.latestReviews // [])[] | {
        author: (.author.login // null),
        state,
        submitted_at: .submittedAt,
        body: (.body // "")
      }
    ],
    comments: [
      (.comments // [])[] | {
        author: (.author.login // null),
        created_at: .createdAt,
        updated_at: .updatedAt,
        body: (.body // "")
      }
    ],
    unresolved_threads: "Unknown",
    status_checks: {
      total: ($checks | length),
      passing: ([
        $checks[] |
        ((.conclusion // .state // .status // "") | ascii_upcase) as $status |
        select(["SUCCESS", "NEUTRAL", "SKIPPED", "COMPLETED"] | index($status))
      ] | length),
      pending: ([
        $checks[] |
        ((.conclusion // .state // .status // "") | ascii_upcase) as $status |
        select(["EXPECTED", "PENDING", "QUEUED", "REQUESTED", "WAITING", "IN_PROGRESS"] | index($status))
      ] | length),
      failing: ([
        $checks[] |
        ((.conclusion // .state // .status // "") | ascii_upcase) as $status |
        select(["ACTION_REQUIRED", "CANCELLED", "ERROR", "FAILURE", "TIMED_OUT"] | index($status))
      ] | length),
      raw: $checks
    }
  }' \
  "$pr_file"
