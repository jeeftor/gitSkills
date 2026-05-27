# GitHub Workflow Reference

Use this reference when remotes, URLs, or user input identify GitHub.

## Commands

- Current user: `gh api user --jq .login`
- Current repo from remote: `gh repo view --json nameWithOwner,url,defaultBranchRef`
- List PRs: `gh pr list --json number,title,url,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt,headRefName,baseRefName`
- View PR: `gh pr view <number> --json number,title,url,isDraft,mergeStateStatus,reviewDecision,reviews,comments,statusCheckRollup,updatedAt,headRefName,baseRefName,headRefOid`
- Current branch PR: `gh pr view --json number,title,url,headRefName,baseRefName,state,isDraft`
- Branch PR fallback: `gh pr list --head <branch> --state open --json number,title,url,headRefName,baseRefName,isDraft`
- PR checks: `gh pr checks <number>`
- List issues: `gh issue list --json number,title,url,state,labels,assignees,updatedAt`

Use GraphQL when unresolved review thread counts or mergeability details are missing from `gh pr view`.

## Pull Requests

When an installed or repo-local helper is available, prefer it for PR table data:

```bash
scripts/git/gh-get-prs.sh --repo <owner/repo> --state open --scope all --limit 50
```

Use `--scope authored`, `--scope assigned`, or `--scope review` when the user asks for PRs they authored, PRs assigned to them, or PRs needing their review.

The helper emits normalized JSON for table summaries, including draft state, review decision, merge state, branches, labels, assignees, and status-check counts.

Fallback command:

- List PRs: `gh pr list --repo <owner/repo> --state open --limit 50 --json number,title,url,state,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt,headRefName,baseRefName,author,assignees,labels,reviewRequests`

## Issues

When an installed or repo-local helper is available, prefer it for issue table data:

```bash
scripts/git/gh-get-issues.sh --repo <owner/repo> --state open --limit 50
```

The helper emits normalized JSON and includes GitHub REST fields that `gh issue list` omits, including `parent_issue_url`, `sub_issues_summary`, and `issue_dependencies_summary`.

Fallback commands:

- List issues: `gh issue list --repo <owner/repo> --state open --limit 50 --json number,title,url,state,labels,assignees,updatedAt`
- Issue details: `gh api repos/<owner>/<repo>/issues/<number>`

## Create And Update

- Create draft PR: `gh pr create --draft --base <base> --head <branch> --title <title> --body-file <file>`
- Create ready PR: `gh pr create --base <base> --head <branch> --title <title> --body-file <file>`
- Edit title/body: `gh pr edit <number> --title <title> --body-file <file>`
- Mark ready: `gh pr ready <number>`
- Checkout PR: `gh pr checkout <number>`

Prefer `--body-file` over generated inline bodies when the repo has a PR template.

## CI And Runs

When an installed or repo-local helper is available, prefer it for CI watch data:

```bash
scripts/git/gh-get-ci.sh --repo <owner/repo> --target-type branch --target <branch>
scripts/git/gh-get-ci.sh --repo <owner/repo> --target-type pr --target <number>
scripts/git/gh-get-ci.sh --repo <owner/repo> --target-type run --target <run-id>
```

The helper emits normalized JSON for summaries, including status, jobs, failed logs, URL, commit, and branch fields.

- PR checks: `gh pr checks <number> --repo <owner/repo>`
- Workflow runs for branch: `gh run list --repo <owner/repo> --branch <branch> --limit 20`
- Workflow run summary: `gh run view <run-id> --repo <owner/repo> --json status,conclusion,jobs,headSha,url`
- Failed logs: `gh run view <run-id> --repo <owner/repo> --log-failed`
- Rerun failed jobs only when explicitly asked: `gh run rerun <run-id> --failed --repo <owner/repo>`

Treat missing check data as unknown. Do not treat skipped or absent checks as passing without required-check evidence.

## Review And Threads

- Review data: `gh pr view <number> --json reviews,comments,reviewDecision,latestReviews`
- Diff: `gh pr diff <number>`
- Use GraphQL for review threads and unresolved states when needed.

Do not resolve comments, submit reviews, or edit PR text from read-only watcher/table workflows.

## Merge

- Merge with repo default when unambiguous: `gh pr merge <number>`
- Squash: `gh pr merge <number> --squash`
- Rebase: `gh pr merge <number> --rebase`
- Merge commit: `gh pr merge <number> --merge`
- Auto-merge only when explicitly requested: `gh pr merge <number> --auto`

Confirm merge method when the repository supports multiple options or policy is unclear.

## Pull Request Notes

GitHub pull requests can have draft state, review decisions, checks, review threads, merge queues, and branch protection. Treat missing fields as unknown rather than successful.
