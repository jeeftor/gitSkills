#!/bin/sh
set -eu

unset CDPATH

die() {
  echo "$1" >&2
  exit "${2:-1}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Missing required command: $1" 127
  fi
}

assert_json() {
  file="$1"
  filter="$2"
  description="$3"

  if ! jq -e "$filter" "$file" >/dev/null; then
    echo "Assertion failed: $description" >&2
    echo "Filter: $filter" >&2
    jq . "$file" >&2 || true
    exit 1
  fi
}

assert_file_contains() {
  file="$1"
  expected="$2"
  description="$3"

  content="$(cat "$file")"
  case "$content" in
    *"$expected"*) ;;
    *)
      echo "Assertion failed: $description" >&2
      echo "Expected to find: $expected" >&2
      echo "File content:" >&2
      cat "$file" >&2
      exit 1
      ;;
  esac
}

assert_file_not_contains() {
  file="$1"
  unexpected="$2"
  description="$3"

  content="$(cat "$file")"
  case "$content" in
    *"$unexpected"*)
      echo "Assertion failed: $description" >&2
      echo "Expected not to find: $unexpected" >&2
      echo "File content:" >&2
      cat "$file" >&2
      exit 1
      ;;
    *) ;;
  esac
}

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
tmp_dir="$(mktemp -d "${TMPDIR:-/tmp}/gitSkills-local-helpers.XXXXXX")"

cleanup() {
  rm -rf "$tmp_dir"
}
trap cleanup EXIT HUP INT TERM

require_command git
require_command jq

# Keep fixture behavior independent of the developer's global Git config.
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

fixture="$tmp_dir/repo"
mkdir "$fixture"
cd "$fixture"
fixture="$(pwd -P)"

git -c init.defaultBranch=master init >/dev/null
git checkout -B master >/dev/null 2>&1
git config user.name "gitSkills Test"
git config user.email "gitskills@example.invalid"
git config commit.gpgsign false

printf '%s\n' "base" >README.md
git add README.md
git commit -m "initial fixture commit" >/dev/null

git remote add origin https://github.com/example/repo.git
git remote add gitlab git@gitlab.example.com:group/project.git
git remote add upstream git@gitlab.example.com:group/project.git
git update-ref refs/remotes/origin/master HEAD
git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/master

git checkout -b feature/helper-smoke >/dev/null 2>&1
git branch --set-upstream-to=origin/master feature/helper-smoke >/dev/null
printf '%s\n' "feature" >feature.txt
git add feature.txt
git commit -m "feature fixture commit" >/dev/null

printf '%s\n' "staged" >staged.txt
git add staged.txt
printf '%s\n' "changed" >>README.md
printf '%s\n' "untracked" >untracked.txt

resolve_json="$tmp_dir/resolve-target.json"
"$repo_root/scripts/git/resolve-target.sh" >"$resolve_json"
assert_json "$resolve_json" '.host == "github"' "default target resolves the branch upstream host"
assert_json "$resolve_json" '.repo == "example/repo"' "default target resolves the branch upstream repo"
assert_json "$resolve_json" '.source == "branch_upstream"' "default target records branch upstream source"
assert_json "$resolve_json" '.remote == "origin"' "default target records upstream remote"
assert_json "$resolve_json" '.url == "https://github.com/example/repo.git"' "default target records remote URL"

gitlab_json="$tmp_dir/resolve-gitlab.json"
"$repo_root/scripts/git/resolve-target.sh" gitlab >"$gitlab_json"
assert_json "$gitlab_json" '.host == "gitlab"' "named GitLab remote resolves host"
assert_json "$gitlab_json" '.repo == "group/project"' "named GitLab remote resolves repo"
assert_json "$gitlab_json" '.source == "remote"' "named remote records remote source"
assert_json "$gitlab_json" '.remote == "gitlab"' "named remote records remote name"

upstream_json="$tmp_dir/resolve-upstream.json"
"$repo_root/scripts/git/resolve-target.sh" upstream >"$upstream_json"
assert_json "$upstream_json" '.host == "gitlab"' "explicit upstream remote resolves GitLab host"
assert_json "$upstream_json" '.repo == "group/project"' "explicit upstream remote resolves GitLab repo"
assert_json "$upstream_json" '.source == "remote"' "explicit upstream remote records remote source"
assert_json "$upstream_json" '.remote == "upstream"' "explicit upstream remote records remote name"

all_remotes_json="$tmp_dir/resolve-all-remotes.json"
"$repo_root/scripts/git/resolve-target.sh" --all-remotes >"$all_remotes_json"
assert_json "$all_remotes_json" '.host == "mixed"' "all-remotes target reports mixed host"
assert_json "$all_remotes_json" '.repo == null' "all-remotes target has null top-level repo"
assert_json "$all_remotes_json" '.targets | length == 2' "all-remotes target deduplicates repositories"
assert_json "$all_remotes_json" '.targets | any(.host == "github" and .repo == "example/repo")' "all-remotes includes GitHub target"
assert_json "$all_remotes_json" '.targets | any(.host == "gitlab" and .repo == "group/project")' "all-remotes includes GitLab target"
assert_json "$all_remotes_json" '[.targets[] | select(.host == "gitlab" and .repo == "group/project")] | length == 1' "all-remotes deduplicates GitLab remotes"

if "$repo_root/scripts/git/resolve-target.sh" --repo group/project >"$tmp_dir/resolve-explicit-repo-no-host.json" 2>"$tmp_dir/resolve-explicit-repo-no-host.err"; then
  echo "resolve-target.sh --repo without --host should fail" >&2
  cat "$tmp_dir/resolve-explicit-repo-no-host.json" >&2
  exit 1
fi
if ! grep -q -- "--host is required when using --repo" "$tmp_dir/resolve-explicit-repo-no-host.err"; then
  echo "resolve-target.sh --repo without --host should explain the ambiguity" >&2
  cat "$tmp_dir/resolve-explicit-repo-no-host.err" >&2
  exit 1
fi

explicit_gitlab_json="$tmp_dir/resolve-explicit-gitlab.json"
"$repo_root/scripts/git/resolve-target.sh" --host gitlab --repo group/project >"$explicit_gitlab_json"
assert_json "$explicit_gitlab_json" '.host == "gitlab"' "explicit GitLab repo target records host"
assert_json "$explicit_gitlab_json" '.repo == "group/project"' "explicit GitLab repo target records repo"
assert_json "$explicit_gitlab_json" '.source == "explicit"' "explicit GitLab repo target records source"

relative_time_json="$tmp_dir/relative-time.json"
TZ=UTC jq -L "$repo_root/scripts/git/jq" -n \
  --argjson now 1779935400 \
  'include "relative-time";
  {
    github: ("2026-05-28T01:28:50Z" | relative_age($now)),
    gitlab: ("2026-05-27T16:12:25.636-04:00" | relative_age($now)),
    future: ("2026-05-28T03:30:00Z" | relative_age($now))
  }' >"$relative_time_json"
assert_json "$relative_time_json" '.github == "1h ago"' "relative time handles GitHub UTC timestamps"
assert_json "$relative_time_json" '.gitlab == "6h ago"' "relative time handles GitLab offset timestamps"
assert_json "$relative_time_json" '.future == "now"' "relative time clamps future timestamps"

fake_bin="$tmp_dir/fake-bin"
mkdir "$fake_bin"
fake_log="$tmp_dir/fake-cli.log"

cat >"$fake_bin/gh" <<'EOF'
#!/bin/sh
set -eu

printf 'gh' >>"$FAKE_LOG"
for arg in "$@"; do
  printf ' [%s]' "$arg" >>"$FAKE_LOG"
done
printf '\n' >>"$FAKE_LOG"

if [ "$1" = "api" ] && [ "$2" = "user" ]; then
  printf '%s\n' "octo-user"
  exit 0
fi

if [ "$1" = "issue" ] && [ "$2" = "list" ]; then
  printf '%s\n' '[]'
  exit 0
fi

if [ "$1" = "issue" ] && [ "$2" = "view" ]; then
  cat <<'JSON'
{
  "number": 7,
  "title": "Old issue title",
  "url": "https://github.com/example/repo/issues/7",
  "state": "OPEN",
  "author": {"login": "author-user"},
  "assignees": [],
  "labels": [],
  "milestone": null,
  "body": "Old issue body",
  "comments": [],
  "createdAt": "2026-05-28T00:00:00Z",
  "updatedAt": "2026-05-28T01:00:00Z",
  "closedAt": null
}
JSON
  exit 0
fi

echo "unexpected gh call: $*" >&2
exit 64
EOF
chmod +x "$fake_bin/gh"

cat >"$fake_bin/glab" <<'EOF'
#!/bin/sh
set -eu

printf 'glab' >>"$FAKE_LOG"
for arg in "$@"; do
  printf ' [%s]' "$arg" >>"$FAKE_LOG"
done
printf '\n' >>"$FAKE_LOG"

if [ "$1" = "api" ] && [ "$2" = "user" ]; then
  printf '%s\n' '{"username":"gitlab-user"}'
  exit 0
fi

if [ "$1" = "api" ]; then
  printf '%s\n' '[]'
  exit 0
fi

echo "unexpected glab call: $*" >&2
exit 64
EOF
chmod +x "$fake_bin/glab"

github_scope_json="$tmp_dir/github-scope.json"
: >"$fake_log"
FAKE_LOG="$fake_log" PATH="$fake_bin:$PATH" \
  "$repo_root/scripts/git/get-issues.sh" --host github --repo example/repo --state open --scope authored --limit 3 >"$github_scope_json"
assert_json "$github_scope_json" '.host == "github"' "generic issue helper keeps GitHub host"
assert_json "$github_scope_json" '.scope == "authored"' "generic issue helper forwards authored issue scope"
assert_file_contains "$fake_log" "gh [api] [user] [--jq] [.login]" "GitHub issue scope resolves the current user"
assert_file_contains "$fake_log" "gh [issue] [list] [--repo] [example/repo] [--state] [open] [--limit] [3]" "GitHub issue scope uses issue list"
assert_file_contains "$fake_log" "[--author] [octo-user]" "GitHub authored issue scope filters by login"

gitlab_scope_json="$tmp_dir/gitlab-scope.json"
: >"$fake_log"
FAKE_LOG="$fake_log" PATH="$fake_bin:$PATH" \
  "$repo_root/scripts/git/glab/get-issues.sh" --repo group/project --state opened --scope assigned --limit 2 >"$gitlab_scope_json"
assert_json "$gitlab_scope_json" '.host == "gitlab"' "GitLab issue helper keeps GitLab host"
assert_json "$gitlab_scope_json" '.scope == "assigned"' "GitLab issue helper records assigned issue scope"
assert_file_contains "$fake_log" "glab [api] [user]" "GitLab issue scope resolves the current user"
assert_file_contains "$fake_log" "assignee_username=gitlab-user" "GitLab assigned issue scope filters by username"

github_update_json="$tmp_dir/github-update-dry-run.json"
: >"$fake_log"
FAKE_LOG="$fake_log" PATH="$fake_bin:$PATH" \
  "$repo_root/scripts/git/gh/update-issue.sh" --repo example/repo --issue 7 --title "New issue title" >"$github_update_json"
assert_json "$github_update_json" '.host == "github"' "GitHub update helper keeps GitHub host"
assert_json "$github_update_json" '.dry_run == true' "GitHub update helper defaults to dry run"
assert_json "$github_update_json" '.mutated == false' "GitHub update helper does not mutate without --yes"
assert_json "$github_update_json" '.before.title == "Old issue title"' "GitHub update helper includes the before snapshot"
assert_json "$github_update_json" '.action.title == "New issue title"' "GitHub update helper describes the requested title edit"
assert_json "$github_update_json" '.after == null' "GitHub update helper omits after snapshot in dry run"
assert_file_not_contains "$fake_log" "gh [issue] [edit]" "GitHub update dry run does not edit the issue"

branch_state_json="$tmp_dir/branch-state.json"
"$repo_root/scripts/git/get-branch-state.sh" >"$branch_state_json"
assert_json "$branch_state_json" '.repo.root == "'"$fixture"'"' "branch state records repository root"
assert_json "$branch_state_json" '.current_branch == "feature/helper-smoke"' "branch state records current branch"
assert_json "$branch_state_json" '.is_detached == false' "branch state records attached HEAD"
assert_json "$branch_state_json" '.current_head != null' "branch state records current HEAD"
assert_json "$branch_state_json" '.upstream.exists == true' "branch state records existing upstream"
assert_json "$branch_state_json" '.upstream.ref == "origin/master"' "branch state records upstream ref"
assert_json "$branch_state_json" '.base.exists == true' "branch state records existing base"
assert_json "$branch_state_json" '.base.branch == "master"' "branch state records base branch"
assert_json "$branch_state_json" '.base.remote == "origin"' "branch state records base remote"
assert_json "$branch_state_json" '.base.default_branch_resolved == true' "branch state records resolved default branch status"
assert_json "$branch_state_json" '.base.is_default_branch_unknown == false' "branch state records known default branch status"
assert_json "$branch_state_json" '.dirty.is_dirty == true' "branch state records dirty worktree"
assert_json "$branch_state_json" '.dirty.summary.staged == 1' "branch state counts staged entries"
assert_json "$branch_state_json" '.dirty.summary.unstaged == 1' "branch state counts unstaged entries"
assert_json "$branch_state_json" '.dirty.summary.untracked == 1' "branch state counts untracked entries"
assert_json "$branch_state_json" '.dirty.staged | any(.status == "A" and .path == "staged.txt")' "branch state lists staged file"
assert_json "$branch_state_json" '.dirty.unstaged | any(.status == "M" and .path == "README.md")' "branch state lists unstaged file"
assert_json "$branch_state_json" '.dirty.untracked | any(.status == "??" and .path == "untracked.txt")' "branch state lists untracked file"
assert_json "$branch_state_json" '.ahead_behind.upstream.ahead == 1' "branch state records upstream ahead count"
assert_json "$branch_state_json" '.ahead_behind.upstream.behind == 0' "branch state records upstream behind count"
assert_json "$branch_state_json" '.ahead_behind.base.ahead == 1' "branch state records base ahead count"
assert_json "$branch_state_json" '.ahead_behind.base.behind == 0' "branch state records base behind count"

unknown_default_fixture="$tmp_dir/unknown-default"
mkdir "$unknown_default_fixture"
cd "$unknown_default_fixture"
git -c init.defaultBranch=scratch init >/dev/null
git config user.name "gitSkills Test"
git config user.email "gitskills@example.invalid"
git config commit.gpgsign false
printf '%s\n' "base" >README.md
git add README.md
git commit -m "initial fixture commit" >/dev/null
git remote add origin https://github.com/example/unknown-default.git
git update-ref refs/remotes/origin/master HEAD
git checkout -b feature/work >/dev/null 2>&1

unknown_default_json="$tmp_dir/branch-state-unknown-default.json"
"$repo_root/scripts/git/get-branch-state.sh" >"$unknown_default_json"
assert_json "$unknown_default_json" '.base.exists == false' "branch state does not guess origin/master without remote HEAD"
assert_json "$unknown_default_json" '.base.default_branch_resolved == false' "branch state records unresolved default branch status"
assert_json "$unknown_default_json" '.base.is_default_branch_unknown == true' "branch state records unknown default branch status"

fake_bin="$tmp_dir/bin"
mkdir "$fake_bin"

gh_log="$tmp_dir/gh.log"
cat >"$fake_bin/gh" <<'EOF'
#!/bin/sh
set -eu

printf '%s\n' "$*" >>"${GITSKILLS_GH_LOG:?}"

if [ "$1" = "pr" ] && [ "$2" = "list" ]; then
  state=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --state)
        state="${2:?missing state}"
        shift 2
        ;;
      *)
        shift
        ;;
    esac
  done
  case "$state" in
    open) printf '%s\n' '[{"number":5}]' ;;
    all) printf '%s\n' '[{"number":7}]' ;;
    *) printf '%s\n' '[]' ;;
  esac
  exit 0
fi

if [ "$1" = "pr" ] && [ "$2" = "view" ]; then
  number="$3"
  jq -n --argjson number "$number" '{
    number: $number,
    title: "Test PR",
    url: "https://github.com/example/repo/pull/5",
    state: "OPEN",
    isDraft: false,
    statusCheckRollup: [],
    headRefName: "feature/helper-smoke",
    baseRefName: "master",
    headRefOid: "abc123",
    author: {login: "tester"}
  }'
  exit 0
fi

if [ "$1" = "api" ] && [ "$2" = "graphql" ]; then
  if [ "${FAKE_GH_GRAPHQL_FAIL:-0}" = "1" ]; then
    echo "GraphQL disabled in fixture" >&2
    exit 1
  fi
  cat <<'JSON'
{
  "data": {
    "repository": {
      "pullRequest": {
        "reviewThreads": {
          "nodes": [
            {
              "id": "RT_1",
              "isResolved": false,
              "isOutdated": false,
              "path": "src/app.py",
              "line": 42,
              "startLine": 41,
              "originalLine": 42,
              "originalStartLine": 41,
              "comments": {
                "nodes": [
                  {
                    "id": "PRRC_1",
                    "author": {"login": "reviewer"},
                    "body": "Please fix this",
                    "createdAt": "2026-06-01T13:00:00Z",
                    "updatedAt": "2026-06-01T13:05:00Z",
                    "url": "https://github.com/example/repo/pull/7#discussion_r1",
                    "path": "src/app.py",
                    "line": 42,
                    "originalLine": 42,
                    "diffHunk": "@@ -40,3 +40,3 @@"
                  }
                ]
              }
            },
            {
              "id": "RT_2",
              "isResolved": true,
              "isOutdated": false,
              "path": "src/done.py",
              "line": 12,
              "startLine": null,
              "originalLine": 12,
              "originalStartLine": null,
              "comments": {"nodes": []}
            }
          ],
          "pageInfo": {"hasNextPage": false, "endCursor": null}
        }
      }
    }
  }
}
JSON
  exit 0
fi

if [ "$1" = "run" ] && [ "$2" = "view" ]; then
  case "$*" in
    *"--log-failed"*)
      printf '%s\n' \
        'build	Run tests	pytest failed line one' \
        'build	Run tests	pytest failed line two' \
        'lint	Ruff	ruff failed line one'
      exit 0
      ;;
    *)
      jq -n '{
        databaseId: 123,
        status: "completed",
        conclusion: "failure",
        headSha: "abc123",
        url: "https://github.com/example/repo/actions/runs/123",
        headBranch: "feature/helper-smoke",
        displayTitle: "Fixture CI",
        workflowName: "Tests",
        jobs: [
          {
            name: "build",
            status: "completed",
            conclusion: "failure",
            url: "https://github.com/example/repo/actions/runs/123/job/1"
          },
          {
            name: "lint",
            status: "completed",
            conclusion: "failure",
            url: "https://github.com/example/repo/actions/runs/123/job/2"
          }
        ]
      }'
      exit 0
      ;;
  esac
fi

exit 2
EOF
chmod +x "$fake_bin/gh"

glab_log="$tmp_dir/glab.log"
cat >"$fake_bin/glab" <<'EOF'
#!/bin/sh
set -eu

printf '%s\n' "$*" >>"${GITSKILLS_GLAB_LOG:?}"

if [ "$1" != "api" ]; then
  exit 2
fi

case "$2" in
  *'merge_requests?source_branch='*)
    case "$2" in
      *'state=opened'*) printf '%s\n' '[{"iid":11}]' ;;
      *'state=all'*) printf '%s\n' '[{"iid":13}]' ;;
      *) printf '%s\n' '[]' ;;
    esac
    ;;
  *'/discussions')
    cat <<'JSON'
[
  {
    "id": "discussion_unresolved",
    "individual_note": false,
    "resolved": false,
    "notes": [
      {
        "author": {"username": "reviewer"},
        "system": false,
        "resolvable": true,
        "resolved": false,
        "created_at": "2026-06-10T10:26:04.494-04:00",
        "updated_at": "2026-06-10T10:26:04.494-04:00",
        "body": "Please fix this"
      }
    ]
  },
  {
    "id": "note_non_resolvable",
    "individual_note": true,
    "notes": [
      {
        "author": {"username": "tester"},
        "system": false,
        "resolvable": false,
        "created_at": "2026-06-10T10:30:00.000-04:00",
        "updated_at": "2026-06-10T10:30:00.000-04:00",
        "body": "FYI"
      }
    ]
  }
]
JSON
    ;;
  *'/approvals')
    printf '%s\n' '{}'
    ;;
  *'/merge_requests/'*)
    iid=11
    case "$2" in
      *'/merge_requests/13'*) iid=13 ;;
    esac
    jq -n --argjson iid "$iid" '{
      iid: $iid,
      title: "Test MR",
      web_url: "https://gitlab.example.com/group/project/-/merge_requests/11",
      state: "opened",
      draft: false,
      author: {username: "tester"},
      source_branch: "feature/helper-smoke",
      target_branch: "master",
      labels: []
    }'
    ;;
  *)
    exit 2
    ;;
esac
EOF
chmod +x "$fake_bin/glab"

PATH="$fake_bin:$PATH"
export PATH
GITSKILLS_GH_LOG="$gh_log"
GITSKILLS_GLAB_LOG="$glab_log"
export GITSKILLS_GH_LOG GITSKILLS_GLAB_LOG

: >"$gh_log"
"$repo_root/scripts/git/gh/get-pr.sh" --repo example/repo --branch feature/helper-smoke >"$tmp_dir/gh-pr-open.json"
assert_file_contains "$gh_log" "--state open" "GitHub branch lookup defaults to open PRs"
assert_json "$tmp_dir/gh-pr-open.json" '.number == 5' "GitHub branch lookup reads the open PR match"

: >"$gh_log"
"$repo_root/scripts/git/gh/get-pr.sh" --repo example/repo --branch feature/helper-smoke --state all >"$tmp_dir/gh-pr-all.json"
assert_file_contains "$gh_log" "--state all" "GitHub branch lookup allows explicit all-state history"
assert_json "$tmp_dir/gh-pr-all.json" '.number == 7' "GitHub all-state branch lookup reads the history match"

github_pr_json="$tmp_dir/github-pr-threads.json"
"$repo_root/scripts/git/gh/get-pr.sh" --repo example/repo --number 7 >"$github_pr_json"
assert_json "$github_pr_json" '.unresolved_threads_count == 1' "GitHub PR helper counts unresolved review threads"
assert_json "$github_pr_json" '.review_threads | length == 2' "GitHub PR helper emits normalized review thread rows"
assert_json "$github_pr_json" '.review_threads | any(.id == "RT_1" and .is_resolved == false and .path == "src/app.py" and (.comments | length == 1))' "GitHub PR helper normalizes unresolved thread metadata"
assert_json "$github_pr_json" '.review_threads[] | select(.id == "RT_1") | .comments | any(.id == "PRRC_1" and .author == "reviewer" and .body == "Please fix this")' "GitHub PR helper normalizes review thread comments"
assert_json "$github_pr_json" '(.data_gaps // []) | length == 0' "GitHub PR helper reports no data gaps when GraphQL succeeds"

github_pr_gap_json="$tmp_dir/github-pr-thread-gap.json"
FAKE_GH_GRAPHQL_FAIL=1 "$repo_root/scripts/git/gh/get-pr.sh" --repo example/repo --number 7 >"$github_pr_gap_json"
assert_json "$github_pr_gap_json" '.unresolved_threads_count == null' "GitHub PR helper uses null unresolved count when thread data is unavailable"
assert_json "$github_pr_gap_json" '.review_threads == []' "GitHub PR helper emits empty review threads when GraphQL is unavailable"
assert_json "$github_pr_gap_json" '.data_gaps | any(.field == "review_threads" and .reason == "graphql_unavailable")' "GitHub PR helper records a structured GraphQL data gap"

github_ci_json="$tmp_dir/github-ci-failed-logs.json"
"$repo_root/scripts/git/gh/get-ci.sh" --repo example/repo --target-type run --target 123 >"$github_ci_json"
assert_json "$github_ci_json" '.failed_logs | length == 2' "GitHub CI helper groups failed logs per job"
assert_json "$github_ci_json" '.failed_logs | any(.job == "build" and (.summary | contains("pytest failed line one")))' "GitHub CI helper keeps build failed log lines under build"
assert_json "$github_ci_json" '.failed_logs | any(.job == "lint" and (.summary | contains("ruff failed line one")))' "GitHub CI helper keeps lint failed log lines under lint"
assert_json "$github_ci_json" '.failed_logs | all(.job != null)' "GitHub CI helper avoids a single null-job failed log blob when job names are available"

: >"$glab_log"
"$repo_root/scripts/git/glab/get-mr.sh" --repo group/project --branch feature/helper-smoke >"$tmp_dir/glab-mr-opened.json"
assert_file_contains "$glab_log" "state=opened" "GitLab branch lookup defaults to opened MRs"
assert_json "$tmp_dir/glab-mr-opened.json" '.number == 11' "GitLab branch lookup reads the opened MR match"
assert_json "$tmp_dir/glab-mr-opened.json" '.discussions[] | select(.id == "discussion_unresolved") | .resolved == false' "GitLab MR helper preserves unresolved discussion state"
assert_json "$tmp_dir/glab-mr-opened.json" '.discussions[] | select(.id == "discussion_unresolved") | .notes[] | .resolved == false' "GitLab MR helper preserves unresolved note state"
assert_json "$tmp_dir/glab-mr-opened.json" '.unresolved_discussions == 1' "GitLab MR helper counts unresolved resolvable discussions"

: >"$glab_log"
"$repo_root/scripts/git/get-pr.sh" --host gitlab --repo group/project --branch feature/helper-smoke >"$tmp_dir/generic-gitlab-mr-opened.json"
assert_file_contains "$glab_log" "state=opened" "Generic PR helper uses GitLab opened branch lookup for explicit target projects"
assert_json "$tmp_dir/generic-gitlab-mr-opened.json" '.repo == "group/project"' "Generic PR helper preserves explicit GitLab target project"
assert_json "$tmp_dir/generic-gitlab-mr-opened.json" '.unresolved_discussions == 1' "Generic PR helper returns GitLab unresolved discussion details"

: >"$glab_log"
"$repo_root/scripts/git/glab/get-mr.sh" --repo group/project --branch feature/helper-smoke --state all >"$tmp_dir/glab-mr-all.json"
assert_file_contains "$glab_log" "state=all" "GitLab branch lookup allows explicit all-state history"
assert_json "$tmp_dir/glab-mr-all.json" '.number == 13' "GitLab all-state branch lookup reads the history match"

echo "Local helper JSON smoke tests passed."
