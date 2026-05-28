#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/get-prs.sh [remote-or-url|all|authored|assigned|review|all remotes] [--repo owner/name|group/project] [--host github|gitlab] [--remote name] [--state open|closed|merged|all] [--scope all|authored|assigned|review] [--limit n] [--all-remotes]

Collect pull requests or merge requests as normalized JSON after resolving the current GitHub or GitLab repository.
The script is read-only and delegates to the provider-specific PR/MR collector.
EOF
}

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
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

github_state() {
  case "$1" in
    open|opened) printf '%s\n' "open" ;;
    closed) printf '%s\n' "closed" ;;
    merged) printf '%s\n' "merged" ;;
    all) printf '%s\n' "all" ;;
  esac
}

collect_target() {
  target_host="$1"
  target_repo="$2"
  target_state="$3"

  case "$target_host" in
    github)
      "$(script_dir)/gh/get-prs.sh" \
        --repo "$target_repo" \
        --state "$(github_state "$target_state")" \
        --scope "$scope" \
        --limit "$limit" |
        jq '
          def color_hint($value):
            if ["Ready", "Passing", "Approved", "Mergeable", "Current", "None", "No blocker", "Closed"] | index($value) then "green"
            elif ["Draft", "Pending", "Review needed", "Review requested", "Behind", "Triage", "Stale", "Unassigned", "Inspect", "Open"] | index($value) then "yellow"
            elif ["Failing", "Conflict", "Changes requested", "Blocked", "Overdue", "Needs owner"] | index($value) then "red"
            elif ["Unknown", "Missing", "Skipped", "No checks", "No labels", "No assignee"] | index($value) then "cyan"
            else "plain"
            end;
          def state_hint:
            if .is_draft then "Draft"
            else
              ((.state // "") | ascii_downcase) as $state |
              if $state == "open" or $state == "opened" then "Open"
              elif $state == "closed" or $state == "merged" then "Closed"
              else "Unknown"
              end
            end;
          def gh_ci:
            if .status_checks.total == 0 then "Missing"
            elif .status_checks.failing > 0 then "Failing"
            elif .status_checks.pending > 0 then "Pending"
            elif .status_checks.passing == .status_checks.total then "Passing"
            else "Unknown"
            end;
          def gh_review:
            if .is_draft then "Draft"
            elif .review_decision == "APPROVED" then "Approved"
            elif .review_decision == "CHANGES_REQUESTED" then "Changes requested"
            elif .review_decision == "REVIEW_REQUIRED" then "Review needed"
            else "Unknown"
            end;
          def gh_merge:
            if .is_draft then "Draft"
            elif .merge_state_status == "CLEAN" or .merge_state_status == "HAS_HOOKS" then "Mergeable"
            elif .merge_state_status == "BEHIND" then "Behind"
            elif .merge_state_status == "DIRTY" then "Conflict"
            elif .merge_state_status == "BLOCKED" then "Blocked"
            else "Unknown"
            end;
          def gh_branch:
            if .merge_state_status == "BEHIND" then "Behind"
            elif .merge_state_status == "UNKNOWN" then "Unknown"
            else "Current"
            end;
          def gh_blocker:
            gh_ci as $ci |
            gh_review as $review |
            gh_merge as $merge |
            if .is_draft then "Draft"
            elif $ci == "Failing" then "CI failing"
            elif $ci == "Pending" then "CI pending"
            elif $review == "Changes requested" then "Changes requested"
            elif $merge == "Conflict" then "Merge conflict"
            elif $merge == "Blocked" then "Merge blocked"
            elif $merge == "Behind" then "Branch behind"
            elif $review == "Review needed" then "Review needed"
            elif $ci == "Missing" then "No checks"
            else "No blocker"
            end;
          .repo as $payload_repo |
          . + {
            items: [
              .pull_requests[] | {
                host: "github",
                repo: $payload_repo,
                kind: "pr",
                number,
                display: ("#" + (.number | tostring)),
                title,
                url,
                state: (if .is_draft then "Draft" else .state end),
                ci_status: gh_ci,
                review_status: gh_review,
                merge_status: gh_merge,
                branch_status: gh_branch,
                unresolved_discussions: "Unknown",
                blocker: gh_blocker,
                colors: {
                  state: color_hint(state_hint),
                  ci: color_hint(gh_ci),
                  review: color_hint(gh_review),
                  merge: color_hint(gh_merge),
                  branch: color_hint(gh_branch),
                  discussions: color_hint("Unknown"),
                  blocker: color_hint(gh_blocker)
                },
                updated_at,
                head_branch,
                base_branch
              }
            ]
          }'
      ;;
    gitlab)
      "$(script_dir)/glab/get-mrs.sh" \
        --repo "$target_repo" \
        --state "$target_state" \
        --scope "$scope" \
        --limit "$limit" |
        jq '
          def color_hint($value):
            if ["Ready", "Passing", "Approved", "Mergeable", "Current", "None", "No blocker", "Closed", "Resolved"] | index($value) then "green"
            elif ["Draft", "Pending", "Review needed", "Review requested", "Behind", "Triage", "Stale", "Unassigned", "Inspect", "Open"] | index($value) then "yellow"
            elif ["Failing", "Conflict", "Changes requested", "Blocked", "Overdue", "Needs owner", "Unresolved"] | index($value) then "red"
            elif ["Unknown", "Missing", "Skipped", "No checks", "No labels", "No assignee"] | index($value) then "cyan"
            else "plain"
            end;
          def state_hint:
            if .is_draft then "Draft"
            else
              ((.state // "") | ascii_downcase) as $state |
              if $state == "open" or $state == "opened" then "Open"
              elif $state == "closed" or $state == "merged" then "Closed"
              else "Unknown"
              end
            end;
          def gl_ci:
            (.pipeline.status // "") as $status |
            if $status == "" then "Missing"
            elif (["success", "passed"] | index($status)) then "Passing"
            elif (["failed", "canceled"] | index($status)) then "Failing"
            elif (["created", "waiting_for_resource", "preparing", "pending", "running"] | index($status)) then "Pending"
            elif (["skipped", "manual"] | index($status)) then "Skipped"
            else "Unknown"
            end;
          def gl_review:
            if .is_draft then "Draft"
            elif ((.reviewers // []) | length) > 0 then "Review requested"
            else "Unknown"
            end;
          def gl_merge:
            if .is_draft then "Draft"
            elif .has_conflicts == true then "Conflict"
            elif .detailed_merge_status == "mergeable" or .merge_status == "can_be_merged" then "Mergeable"
            elif .detailed_merge_status == "need_rebase" then "Behind"
            elif .detailed_merge_status == "checking" then "Unknown"
            else "Blocked"
            end;
          def gl_branch:
            if .detailed_merge_status == "need_rebase" then "Behind"
            elif .detailed_merge_status == "mergeable" or .merge_status == "can_be_merged" then "Current"
            else "Unknown"
            end;
          def gl_discussions:
            if .blocking_discussions_resolved == true then "Resolved"
            elif .blocking_discussions_resolved == false then "Unresolved"
            else "Unknown"
            end;
          def gl_blocker:
            gl_ci as $ci |
            gl_merge as $merge |
            gl_discussions as $discussions |
            if .is_draft then "Draft"
            elif $ci == "Failing" then "CI failing"
            elif $ci == "Pending" then "CI pending"
            elif $discussions == "Unresolved" then "Unresolved discussions"
            elif $merge == "Conflict" then "Merge conflict"
            elif $merge == "Behind" then "Branch behind"
            elif $merge == "Blocked" then "Merge blocked"
            elif ((.reviewers // []) | length) > 0 then "Review requested"
            else "No blocker"
            end;
          .repo as $payload_repo |
          . + {
            items: [
              .merge_requests[] | {
                host: "gitlab",
                repo: $payload_repo,
                kind: "mr",
                number,
                display: ("!" + (.number | tostring)),
                title,
                url,
                state: (if .is_draft then "Draft" else .state end),
                ci_status: gl_ci,
                review_status: gl_review,
                merge_status: gl_merge,
                branch_status: gl_branch,
                unresolved_discussions: gl_discussions,
                blocker: gl_blocker,
                colors: {
                  state: color_hint(state_hint),
                  ci: color_hint(gl_ci),
                  review: color_hint(gl_review),
                  merge: color_hint(gl_merge),
                  branch: color_hint(gl_branch),
                  discussions: color_hint(gl_discussions),
                  blocker: color_hint(gl_blocker)
                },
                updated_at,
                head_branch,
                base_branch
              }
            ]
          }'
      ;;
    *)
      die "Could not determine PR/MR host. Use --host github or --host gitlab." 2
      ;;
  esac
}

collect_all_remotes() {
  require_command jq

  results_file="$(mktemp)"
  trap 'rm -f "$results_file"' EXIT HUP INT TERM

  target_json="$("$(script_dir)/resolve-target.sh" --all-remotes)"
  printf '%s\n' "$target_json" |
    jq -c '.targets[]' |
    while IFS= read -r resolved_target; do
      target_host="$(printf '%s\n' "$resolved_target" | jq -r '.host')"
      target_repo="$(printf '%s\n' "$resolved_target" | jq -r '.repo')"
      collect_target "$target_host" "$target_repo" "$state" >>"$results_file"
    done

  jq -s \
    --arg state "$state" \
    --arg scope "$scope" \
    --argjson limit "$limit" \
    '{
      host: "mixed",
      repo: null,
      state: $state,
      scope: $scope,
      limit: $limit,
      targets: .,
      items: ([.[] | .items[]])
    }' \
    "$results_file"
}

host=""
repo=""
remote=""
target=""
state="open"
scope="all"
limit="50"
all_remotes=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --host)
      host="${2:?missing value for --host}"
      shift 2
      ;;
    --repo)
      repo="${2:?missing value for --repo}"
      shift 2
      ;;
    --remote)
      remote="${2:?missing value for --remote}"
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
    --all-remotes)
      all_remotes=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*)
      die "Unknown argument: $1" 2
      ;;
    all)
      if [ "$#" -gt 1 ] && [ "$2" = "remotes" ]; then
        all_remotes=1
        shift 2
      else
        scope="all"
        shift
      fi
      ;;
    authored|assigned|review)
      scope="$1"
      shift
      ;;
    remotes)
      die "Use 'all remotes' or --all-remotes for multi-remote collection" 2
      ;;
    *)
      if [ -n "$target" ]; then
        die "Only one remote or URL target is supported" 2
      fi
      target="$1"
      shift
      ;;
  esac
done

case "$host" in
  ""|github|gitlab) ;;
  *) die "Unsupported --host value: $host" 2 ;;
esac

case "$state" in
  open|opened|closed|merged|all) ;;
  *) die "Unsupported --state value: $state" 2 ;;
esac

case "$scope" in
  all|authored|assigned|review) ;;
  *) die "Unsupported --scope value: $scope" 2 ;;
esac

case "$limit" in
  ''|*[!0-9]*)
    die "--limit must be a positive integer" 2
    ;;
  *)
    if [ "$limit" -eq 0 ]; then
      die "--limit must be a positive integer" 2
    fi
    ;;
esac

if [ -n "$remote" ] && [ -n "$target" ]; then
  die "Use either --remote or a positional remote/URL target, not both" 2
fi

if [ "$all_remotes" -eq 1 ]; then
  if [ -n "$remote" ] || [ -n "$target" ] || [ -n "$repo" ]; then
    die "Use all-remotes collection without --repo, --remote, or a positional target" 2
  fi
  collect_all_remotes
  exit 0
fi

require_command jq

set -- "$(script_dir)/resolve-target.sh"
if [ -n "$host" ]; then
  set -- "$@" --host "$host"
fi
if [ -n "$repo" ]; then
  set -- "$@" --repo "$repo"
fi
if [ -n "$remote" ]; then
  set -- "$@" --remote "$remote"
elif [ -n "$target" ]; then
  set -- "$@" "$target"
fi
target_json="$("$@")"
host="$(printf '%s\n' "$target_json" | jq -r '.host')"
repo="$(printf '%s\n' "$target_json" | jq -r '.repo')"

collect_target "$host" "$repo" "$state"
