#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh/get-pr.sh --repo owner/name [--number n|--branch branch] [--state open|all]

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
state="open"

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
    --state)
      state="${2:?missing value for --state}"
      case "$state" in
        open|all) ;;
        *) die "--state must be open or all" 2 ;;
      esac
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
  gh pr list --repo "$repo" --head "$branch" --state "$state" --limit 2 --json number >"$matches_file"
  match_count="$(jq 'length' "$matches_file")"
  case "$match_count" in
    0) die "Could not find a GitHub pull request for branch: $branch" 2 ;;
    1) number="$(jq -r '.[0].number' "$matches_file")" ;;
    *) die "More than one GitHub pull request matched branch: $branch" 2 ;;
  esac
fi

pr_file="$(mktemp)"
threads_file="$(mktemp)"
threads_raw_file="$(mktemp)"
threads_error_file="$(mktemp)"
trap 'rm -f "${matches_file:-}" "$pr_file" "$threads_file" "$threads_raw_file" "$threads_error_file"' EXIT HUP INT TERM

gh pr view "$number" \
  --repo "$repo" \
  --json number,title,url,state,isDraft,mergeStateStatus,reviewDecision,reviews,latestReviews,comments,statusCheckRollup,updatedAt,createdAt,closedAt,mergedAt,headRefName,baseRefName,headRefOid,author,assignees,labels,reviewRequests,body \
  >"$pr_file"

write_thread_gap() {
  reason="$1"
  message="$2"

  jq -n \
    --arg reason "$reason" \
    --arg message "$message" \
    '{
      review_threads: [],
      unresolved_threads_count: null,
      data_gaps: [{field: "review_threads", reason: $reason, message: $message}]
    }' >"$threads_file"
}

case "$repo" in
  */*)
    owner="${repo%%/*}"
    name="${repo#*/}"
    # shellcheck disable=SC2016
    query='
      query($owner: String!, $name: String!, $number: Int!) {
        repository(owner: $owner, name: $name) {
          pullRequest(number: $number) {
            reviewThreads(first: 100) {
              nodes {
                id
                isResolved
                isOutdated
                path
                line
                startLine
                originalLine
                originalStartLine
                comments(first: 100) {
                  nodes {
                    id
                    author {
                      login
                    }
                    body
                    createdAt
                    updatedAt
                    url
                    path
                    line
                    originalLine
                    diffHunk
                  }
                  pageInfo {
                    hasNextPage
                    endCursor
                  }
                }
              }
              pageInfo {
                hasNextPage
                endCursor
              }
            }
          }
        }
      }'

    if gh api graphql -f owner="$owner" -f name="$name" -F number="$number" -f query="$query" >"$threads_raw_file" 2>"$threads_error_file" &&
      jq '
        (.data.repository.pullRequest.reviewThreads // null) as $threads |
        if $threads == null then
          error("missing reviewThreads")
        else
          ($threads.nodes // []) as $nodes |
          {
            review_threads: [
              $nodes[] | {
                id,
                is_resolved: (if has("isResolved") then .isResolved elif has("is_resolved") then .is_resolved else null end),
                is_outdated: (if has("isOutdated") then .isOutdated elif has("is_outdated") then .is_outdated else null end),
                path: (.path // null),
                line: (.line // null),
                start_line: (.startLine // .start_line // null),
                original_line: (.originalLine // .original_line // null),
                original_start_line: (.originalStartLine // .original_start_line // null),
                comments: [
                  (.comments.nodes // [])[] | {
                    id,
                    author: (.author.login // null),
                    created_at: (.createdAt // .created_at // null),
                    updated_at: (.updatedAt // .updated_at // null),
                    url: (.url // null),
                    path: (.path // null),
                    line: (.line // null),
                    original_line: (.originalLine // .original_line // null),
                    diff_hunk: (.diffHunk // .diff_hunk // ""),
                    body: (.body // "")
                  }
                ],
                comments_truncated: (.comments.pageInfo.hasNextPage // .comments.page_info.has_next_page // false)
              }
            ],
            unresolved_threads_count: ([
              $nodes[] |
              (if has("isResolved") then .isResolved elif has("is_resolved") then .is_resolved else true end) as $is_resolved |
              select($is_resolved == false)
            ] | length),
            data_gaps: (
              [
                if ($threads.pageInfo.hasNextPage // $threads.page_info.has_next_page // false) then
                  {field: "review_threads", reason: "pagination_truncated", message: "Only the first 100 review threads were collected."}
                else empty end,
                $nodes[] |
                  select(.comments.pageInfo.hasNextPage // .comments.page_info.has_next_page // false) |
                  {field: "review_threads.comments", reason: "pagination_truncated", message: ("Only the first 100 comments were collected for thread " + (.id // "unknown") + ".")}
              ]
            )
          }
        end' "$threads_raw_file" >"$threads_file" 2>/dev/null; then
      :
    else
      write_thread_gap "graphql_unavailable" "GitHub review thread GraphQL data was unavailable."
    fi
    ;;
  *)
    write_thread_gap "invalid_repo" "GitHub review thread GraphQL requires a repo in owner/name form."
    ;;
esac

jq \
  --arg host "github" \
  --arg repo "$repo" \
  --slurpfile thread_data "$threads_file" '
  ($thread_data[0] // {review_threads: [], unresolved_threads_count: null, data_gaps: []}) as $thread_data |
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
    review_threads: ($thread_data.review_threads // []),
    unresolved_threads_count: ($thread_data.unresolved_threads_count // null),
    unresolved_threads: ($thread_data.unresolved_threads_count // "Unknown"),
    data_gaps: ($thread_data.data_gaps // []),
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
  }' "$pr_file"
