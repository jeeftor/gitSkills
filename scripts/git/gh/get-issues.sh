#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh/get-issues.sh [--repo owner/name] [--state open|closed|all] [--limit n]

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

issues_file="$(mktemp)"
trap 'rm -f "$issues_file"' EXIT HUP INT TERM

gh issue list \
  --repo "$repo" \
  --state "$state" \
  --limit "$limit" \
  --json number,title,url,state,updatedAt >"$issues_file"

jq \
  --arg host "github" \
  --arg repo "$repo" \
  --arg state "$state" \
  --argjson limit "$limit" \
  '
  {
    host: $host,
    repo: $repo,
    state: $state,
    limit: $limit,
    issues: [
      .[] |
      {
        number,
        title,
        url,
        state,
        updated_at: .updatedAt,
        table: {
          display: ("#" + (.number | tostring)),
          updated_at: .updatedAt
        }
      }
    ]
  }' \
  "$issues_file"
