#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/glab-get-ci.sh --repo group/project [--target-type mr|branch|commit|pipeline] [--target value] [--limit n]

Collect GitLab pipeline/job status as normalized JSON for gitSkills CI workflows.
The script is read-only and uses glab for repository access.
EOF
}

repo=""
target_type="branch"
target=""
limit="20"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --target-type)
      target_type="${2:?missing value for --target-type}"
      shift 2
      ;;
    --target)
      target="${2:?missing value for --target}"
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

case "$target_type" in
  mr|branch|commit|pipeline) ;;
  *)
    echo "Unsupported --target-type value: $target_type" >&2
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
  echo "--repo is required for GitLab CI collection" >&2
  exit 2
fi

for command_name in glab jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 127
  fi
done

if [ "$target_type" = "branch" ] && [ -z "$target" ]; then
  target="$(git branch --show-current 2>/dev/null || true)"
  if [ -z "$target" ]; then
    echo "--target is required when the current branch cannot be detected" >&2
    exit 2
  fi
fi

project_path="$(printf '%s' "$repo" | jq -sRr @uri)"
pipeline_file="$(mktemp)"
jobs_file="$(mktemp)"
logs_file="$(mktemp)"
trap 'rm -f "$pipeline_file" "$jobs_file" "$logs_file"' EXIT HUP INT TERM

# shellcheck disable=SC2016
status_expr='
  def normalize_status:
    ascii_downcase as $s |
    if ["success", "passed"] | index($s) then "Pass"
    elif ["failed", "failure"] | index($s) then "Failing"
    elif ["canceled", "cancelled"] | index($s) then "Canceled"
    elif ["skipped"] | index($s) then "Skipped"
    elif ["created", "waiting_for_resource", "preparing", "pending", "running", "manual", "scheduled"] | index($s) then "Pending"
    elif $s == "" then "Unknown"
    else "Unknown"
    end;
  def aggregate($items; $pipeline_status):
    if ($items | length) == 0 then ($pipeline_status | normalize_status)
    elif any($items[]; .status == "Failing") then "Failing"
    elif any($items[]; .status == "Canceled") then "Canceled"
    elif any($items[]; .status == "Pending") then "Pending"
    elif all($items[]; .status == "Skipped") then "Skipped"
    elif all($items[]; (.status == "Pass" or .status == "Skipped")) then "Pass"
    else ($pipeline_status | normalize_status)
    end;
'

case "$target_type" in
  pipeline)
    if [ -z "$target" ]; then
      echo "--target is required for --target-type pipeline" >&2
      exit 2
    fi
    pipeline_id="$target"
    ;;
  mr)
    if [ -z "$target" ]; then
      echo "--target is required for --target-type mr" >&2
      exit 2
    fi
    glab api "projects/$project_path/merge_requests/$target" >"$pipeline_file"
    pipeline_id="$(jq -r '.head_pipeline.id // empty' "$pipeline_file")"
    if [ -z "$pipeline_id" ]; then
      jq -n \
        --arg host "gitlab" \
        --arg repo "$repo" \
        --arg type "$target_type" \
        --arg value "$target" \
        --arg url "$(jq -r '.web_url // empty' "$pipeline_file")" \
        '{host: $host, repo: $repo, target: {type: $type, value: $value}, status: "Missing", url: (if $url == "" then null else $url end), commit: null, branch: null, jobs: [], failed_logs: []}'
      exit 0
    fi
    ;;
  branch|commit)
    query="per_page=$limit"
    if [ "$target_type" = "branch" ]; then
      query="$query&ref=$(printf '%s' "$target" | jq -sRr @uri)"
    else
      if [ -z "$target" ]; then
        echo "--target is required for --target-type commit" >&2
        exit 2
      fi
      query="$query&sha=$(printf '%s' "$target" | jq -sRr @uri)"
    fi
    glab api "projects/$project_path/pipelines?$query" >"$pipeline_file"
    pipeline_id="$(jq -r '.[0].id // empty' "$pipeline_file")"
    if [ -z "$pipeline_id" ]; then
      jq -n \
        --arg host "gitlab" \
        --arg repo "$repo" \
        --arg type "$target_type" \
        --arg value "$target" \
        '{host: $host, repo: $repo, target: {type: $type, value: $value}, status: "Missing", url: null, commit: null, branch: null, jobs: [], failed_logs: []}'
      exit 0
    fi
    ;;
esac

glab api "projects/$project_path/pipelines/$pipeline_id" >"$pipeline_file"
glab api "projects/$project_path/pipelines/$pipeline_id/jobs?per_page=100" >"$jobs_file"

jq -r '.[] | select((.status // "") == "failed") | [.id, .name] | @tsv' "$jobs_file" |
  while IFS="$(printf '\t')" read -r job_id job_name; do
    [ -n "$job_id" ] || continue
    trace_file="$(mktemp)"
    if glab api "projects/$project_path/jobs/$job_id/trace" >"$trace_file" 2>/dev/null; then
      jq -n \
        --arg job "$job_name" \
        --rawfile trace "$trace_file" \
        '{job: $job, summary: ($trace | split("\n") | .[:120] | join("\n"))}' >>"$logs_file"
    fi
    rm -f "$trace_file"
  done

jq \
  --arg host "gitlab" \
  --arg repo "$repo" \
  --arg type "$target_type" \
  --arg value "$target" \
  --slurpfile jobs "$jobs_file" \
  --slurpfile failed_logs "$logs_file" \
  "$status_expr"'
  ($jobs[0] // []) as $raw_jobs |
  [
    $raw_jobs[] |
    {
      name,
      status: ((.status // "") | normalize_status),
      url: (.web_url // null),
      required: null,
      summary: (.status // "unknown")
    }
  ] as $jobs |
  {
    host: $host,
    repo: $repo,
    target: {
      type: $type,
      value: (if $value == "" then (.id | tostring) else $value end)
    },
    status: aggregate($jobs; (.status // "")),
    url: (.web_url // null),
    commit: (.sha // null),
    branch: (.ref // null),
    pipeline_id: (.id // null),
    jobs: $jobs,
    failed_logs: ($failed_logs // [])
  }' "$pipeline_file"
