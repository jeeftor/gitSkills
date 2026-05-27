#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab/create-issue.sh --repo group/project --title title [--body text|--body-file file] [--duplicate-limit n] [--allow-duplicate] [--yes]

Create a GitLab issue after searching open issues for likely duplicates.
Without --yes, the script only reports the target and duplicate candidates.
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
title=""
body=""
body_file=""
duplicate_limit="10"
allow_duplicate="0"
assume_yes="0"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --title)
      title="${2:?missing value for --title}"
      shift 2
      ;;
    --body)
      body="${2:?missing value for --body}"
      shift 2
      ;;
    --body-file)
      body_file="${2:?missing value for --body-file}"
      shift 2
      ;;
    --duplicate-limit)
      duplicate_limit="${2:?missing value for --duplicate-limit}"
      shift 2
      ;;
    --allow-duplicate)
      allow_duplicate="1"
      shift
      ;;
    --yes)
      assume_yes="1"
      shift
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
[ -n "$title" ] || die "--title is required" 2

if [ -n "$body" ] && [ -n "$body_file" ]; then
  die "Use either --body or --body-file, not both" 2
fi

case "$duplicate_limit" in
  ''|*[!0-9]*)
    die "--duplicate-limit must be a positive integer" 2
    ;;
  *)
    if [ "$duplicate_limit" -eq 0 ]; then
      die "--duplicate-limit must be a positive integer" 2
    fi
    ;;
esac

require_command glab
require_command jq

raw_duplicates_file="$(mktemp)"
duplicates_file="$(mktemp)"
created_file="$(mktemp)"
trap 'rm -f "$raw_duplicates_file" "$duplicates_file" "$created_file"' EXIT HUP INT TERM

project_path="$(printf '%s' "$repo" | jq -sRr @uri)"
search_query="$(printf '%s' "$title" | jq -sRr @uri)"

glab api "projects/$project_path/issues?state=opened&search=$search_query&per_page=$duplicate_limit" >"$raw_duplicates_file"

jq '[.[] | {
      number: (.iid // .id),
      title,
      url: (.web_url // .webUrl // .url),
      state
    }]' "$raw_duplicates_file" >"$duplicates_file"

duplicate_count="$(jq 'length' "$duplicates_file")"

if [ "$assume_yes" != "1" ]; then
  jq -n \
    --arg host "gitlab" \
    --arg repo "$repo" \
    --arg title "$title" \
    --argjson duplicate_count "$duplicate_count" \
    --slurpfile candidates "$duplicates_file" \
    '{
      host: $host,
      repo: $repo,
      title: $title,
      dry_run: true,
      created: false,
      duplicate_blocked: false,
      duplicate_count: $duplicate_count,
      duplicate_candidates: $candidates[0],
      message: "Pass --yes to create the issue after explicit user intent is confirmed."
    }'
  exit 0
fi

if [ "$duplicate_count" -gt 0 ] && [ "$allow_duplicate" != "1" ]; then
  jq -n \
    --arg host "gitlab" \
    --arg repo "$repo" \
    --arg title "$title" \
    --argjson duplicate_count "$duplicate_count" \
    --slurpfile candidates "$duplicates_file" \
    '{
      host: $host,
      repo: $repo,
      title: $title,
      dry_run: false,
      created: false,
      duplicate_blocked: true,
      duplicate_count: $duplicate_count,
      duplicate_candidates: $candidates[0],
      message: "Likely duplicate open issues were found. Re-run with --allow-duplicate only after the user confirms."
    }'
  exit 3
fi

if [ -n "$body_file" ]; then
  [ -f "$body_file" ] || die "Body file does not exist: $body_file" 2
  description="$(cat "$body_file")"
else
  description="$body"
fi

glab api "projects/$project_path/issues" \
  -X POST \
  -F "title=$title" \
  -F "description=$description" >"$created_file"

jq \
  --arg host "gitlab" \
  --arg repo "$repo" \
  --arg title "$title" \
  --argjson duplicate_count "$duplicate_count" \
  --slurpfile candidates "$duplicates_file" \
  '{
    host: $host,
    repo: $repo,
    title: $title,
    dry_run: false,
    created: true,
    url: .web_url,
    issue: {
      number: .iid,
      url: .web_url
    },
    duplicate_count: $duplicate_count,
    duplicate_candidates: $candidates[0]
  }' "$created_file"
