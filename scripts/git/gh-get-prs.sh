#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh-get-prs.sh [--repo owner/name] [--state open|closed|merged|all] [--scope all|authored|assigned|review] [--limit n]

Collect GitHub pull requests as normalized JSON for gitSkills table workflows.
The script is read-only and uses gh for repository access.
EOF
}

repo=""
state="open"
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
  open|closed|merged|all) ;;
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

for command_name in gh jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 127
  fi
done

if [ -z "$repo" ]; then
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi

set -- gh pr list \
  --repo "$repo" \
  --state "$state" \
  --limit "$limit" \
  --json number,title,url,state,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt,headRefName,baseRefName,author,assignees,labels,reviewRequests

case "$scope" in
  authored)
    set -- "$@" --author "@me"
    ;;
  assigned)
    set -- "$@" --assignee "@me"
    ;;
  review)
    set -- "$@" --search "review-requested:@me"
    ;;
esac

prs_file="$(mktemp)"
trap 'rm -f "$prs_file"' EXIT HUP INT TERM

"$@" >"$prs_file"

jq \
    --arg host "github" \
    --arg repo "$repo" \
    --arg state "$state" \
    --arg scope "$scope" \
    --argjson limit "$limit" \
    '{
      host: $host,
      repo: $repo,
      state: $state,
      scope: $scope,
      limit: $limit,
      pull_requests: [
        .[] |
        (.statusCheckRollup // []) as $checks |
        {
          number,
          title,
          url,
          state,
          is_draft: (.isDraft // false),
          labels: [(.labels // [])[].name],
          assignees: [(.assignees // [])[].login],
          author: (.author.login // null),
          review_requests: [
            (.reviewRequests // [])[] |
            (.login // .slug // .name // empty)
          ],
          updated_at: .updatedAt,
          head_branch: .headRefName,
          base_branch: .baseRefName,
          review_decision: (.reviewDecision // "UNKNOWN"),
          merge_state_status: (.mergeStateStatus // "UNKNOWN"),
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
            ] | length)
          }
        }
      ]
    }' \
    "$prs_file"
