#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/gh-get-ci.sh [--repo owner/name] [--target-type pr|branch|commit|run] [--target value] [--limit n]

Collect GitHub Actions/check status as normalized JSON for gitSkills CI workflows.
The script is read-only and uses gh for repository access.
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
  pr|branch|commit|run) ;;
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

for command_name in gh jq; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    echo "Missing required command: $command_name" >&2
    exit 127
  fi
done

if [ -z "$repo" ]; then
  repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
fi

if [ "$target_type" = "branch" ] && [ -z "$target" ]; then
  target="$(git branch --show-current 2>/dev/null || true)"
  if [ -z "$target" ]; then
    echo "--target is required when the current branch cannot be detected" >&2
    exit 2
  fi
fi

checks_file="$(mktemp)"
run_file="$(mktemp)"
logs_file="$(mktemp)"
trap 'rm -f "$checks_file" "$run_file" "$logs_file"' EXIT HUP INT TERM

# shellcheck disable=SC2016
status_expr='
  def normalize_status:
    ascii_downcase as $s |
    if ["success", "pass", "completed"] | index($s) then "Pass"
    elif ["failure", "failed", "error", "timed_out", "action_required", "startup_failure", "fail"] | index($s) then "Failing"
    elif ["cancelled", "canceled", "cancel"] | index($s) then "Canceled"
    elif ["skipped", "skipping", "neutral"] | index($s) then "Skipped"
    elif ["queued", "pending", "requested", "waiting", "in_progress"] | index($s) then "Pending"
    elif $s == "" then "Unknown"
    else "Unknown"
    end;
  def aggregate($items):
    if ($items | length) == 0 then "Missing"
    elif any($items[]; .status == "Failing") then "Failing"
    elif any($items[]; .status == "Canceled") then "Canceled"
    elif any($items[]; .status == "Pending") then "Pending"
    elif all($items[]; .status == "Skipped") then "Skipped"
    elif all($items[]; (.status == "Pass" or .status == "Skipped")) then "Pass"
    else "Unknown"
    end;
'

if [ "$target_type" = "pr" ]; then
  set -- gh pr checks
  if [ -n "$target" ]; then
    set -- "$@" "$target"
  fi
  set -- "$@" --repo "$repo" --json bucket,completedAt,description,event,link,name,startedAt,state,workflow
  "$@" >"$checks_file" 2>/dev/null || true

  set -- gh pr view
  if [ -n "$target" ]; then
    set -- "$@" "$target"
  fi
  set -- "$@" --repo "$repo" --json number,url,headRefOid,headRefName
  "$@" >"$run_file"

  if [ ! -s "$checks_file" ]; then
    jq -n \
      --arg host "github" \
      --arg repo "$repo" \
      --arg type "$target_type" \
      --arg value "$target" \
      --slurpfile pr "$run_file" \
      '($pr[0] // {}) as $pr_data |
      {
        host: $host,
        repo: $repo,
        target: {
          type: $type,
          value: (if $value == "" then ($pr_data.number | tostring) else $value end)
        },
        status: "Missing",
        url: ($pr_data.url // null),
        commit: ($pr_data.headRefOid // null),
        branch: ($pr_data.headRefName // null),
        jobs: [],
        failed_logs: []
      }'
    exit 0
  fi

  jq \
    --arg host "github" \
    --arg repo "$repo" \
    --arg type "$target_type" \
    --arg value "$target" \
    --slurpfile pr "$run_file" \
    "$status_expr"'
    ($pr[0] // {}) as $pr_data |
    [
      .[] |
      {
        name,
        status: ((.bucket // .state // "") | normalize_status),
        url: (.link // null),
        required: null,
        summary: ((.workflow // "check") + ": " + (.state // "unknown"))
      }
    ] as $jobs |
    {
      host: $host,
      repo: $repo,
      target: {
        type: $type,
        value: (if $value == "" then ($pr_data.number | tostring) else $value end)
      },
      status: aggregate($jobs),
      url: ($pr_data.url // null),
      commit: ($pr_data.headRefOid // null),
      branch: ($pr_data.headRefName // null),
      jobs: $jobs,
      failed_logs: []
    }' "$checks_file"
  exit 0
fi

if [ "$target_type" = "run" ]; then
  if [ -z "$target" ]; then
    echo "--target is required for --target-type run" >&2
    exit 2
  fi
  run_id="$target"
else
  set -- gh run list --repo "$repo" --limit "$limit" --json databaseId,status,conclusion,headSha,url,name,displayTitle,headBranch,workflowName
  case "$target_type" in
    branch)
      set -- "$@" --branch "$target"
      ;;
    commit)
      if [ -z "$target" ]; then
        echo "--target is required for --target-type commit" >&2
        exit 2
      fi
      set -- "$@" --commit "$target"
      ;;
  esac
  "$@" >"$checks_file"
  run_id="$(jq -r '.[0].databaseId // empty' "$checks_file")"
  if [ -z "$run_id" ]; then
    jq -n \
      --arg host "github" \
      --arg repo "$repo" \
      --arg type "$target_type" \
      --arg value "$target" \
      '{host: $host, repo: $repo, target: {type: $type, value: $value}, status: "Missing", url: null, commit: null, branch: null, jobs: [], failed_logs: []}'
    exit 0
  fi
fi

gh run view "$run_id" \
  --repo "$repo" \
  --json databaseId,status,conclusion,headSha,url,jobs,headBranch,displayTitle,workflowName >"$run_file"

if ! gh run view "$run_id" --repo "$repo" --log-failed >"$logs_file" 2>/dev/null; then
  : >"$logs_file"
fi

jq \
  --arg host "github" \
  --arg repo "$repo" \
  --arg type "$target_type" \
  --arg value "$target" \
  --arg run_id "$run_id" \
  --rawfile failed_logs "$logs_file" \
  "$status_expr"'
  [
    (.jobs // [])[] |
    {
      name,
      status: ((.conclusion // .status // "") | normalize_status),
      url: (.url // null),
      required: null,
      summary: ((.status // "unknown") + "/" + (.conclusion // "unknown"))
    }
  ] as $jobs |
  {
    host: $host,
    repo: $repo,
    target: {
      type: $type,
      value: (if $value == "" then $run_id else $value end)
    },
    status: aggregate($jobs),
    url: (.url // null),
    commit: (.headSha // null),
    branch: (.headBranch // null),
    run_id: (.databaseId // ($run_id | tonumber?)),
    jobs: $jobs,
    failed_logs: (
      if ($failed_logs | length) > 0 then
        [{job: null, summary: ($failed_logs | split("\n") | .[:120] | join("\n"))}]
      else
        []
      end
    )
  }' "$run_file"
