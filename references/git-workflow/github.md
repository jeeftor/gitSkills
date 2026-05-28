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

When an installed or repo-local helper is available, prefer it for PR table and detail data:

```bash
scripts/git/get-prs.sh --state open --scope all --limit 50
scripts/git/get-prs.sh origin --state open --scope all --limit 50
scripts/git/get-pr.sh <number-or-url>
scripts/git/get-pr.sh --branch <branch>
scripts/git/gh/get-prs.sh --repo <owner/repo> --state open --scope all --limit 50
scripts/git/gh/get-pr.sh --repo <owner/repo> --number <number>
```

Use `--scope authored`, `--scope assigned`, or `--scope review` when the user asks for PRs they authored, PRs assigned to them, or PRs needing their review.

The generic list helper resolves the current checkout or named remote before delegating to the GitHub helper. It keeps list collection narrow and emits a table-ready `items` list with draft state, CI status, review status, mergeability, branch freshness, URLs, and blocker text. The generic detail helper resolves one PR by URL, number, or branch and emits body, comments, reviews, merge state, branches, and status checks. GitHub helpers remain available for direct provider-specific collection.

Fallback command:

- List PRs: `gh pr list --repo <owner/repo> --state open --limit 50 --json number,title,url,state,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt,headRefName,baseRefName,author,assignees,labels,reviewRequests`

## Issues

When an installed or repo-local helper is available, prefer it for issue table data:

```bash
scripts/git/get-issues.sh --state open --limit 50
scripts/git/get-issues.sh origin --state open --limit 50
scripts/git/gh/get-issues.sh --repo <owner/repo> --state open --limit 50
```

The generic helper resolves the current checkout or named remote before delegating to the GitHub helper. The GitHub helper emits lightweight normalized JSON for issue tables.

Fallback commands:

- List issues: `gh issue list --repo <owner/repo> --state open --limit 50 --json number,title,url,state,updatedAt`
- Issue details: `gh api repos/<owner>/<repo>/issues/<number>`

## Create And Update

When an installed or repo-local helper is available, prefer it for issue creation after explicit user intent is confirmed:

```bash
scripts/git/create-issue.sh --title "Issue title" --body-file <file>
scripts/git/create-issue.sh --title "Issue title" --body-file <file> --yes
scripts/git/gh/create-issue.sh --repo <owner/repo> --title "Issue title" --body-file <file> --yes
```

The issue create helper searches likely duplicate open issues before creating. Without `--yes`, it emits JSON describing the target and duplicate candidates without mutating issue state.

- Create issue: `gh issue create --repo <owner/repo> --title <title> --body-file <file>`
- Comment on issue: `gh issue comment <number> --repo <owner/repo> --body-file <file>`
- Edit title/body: `gh issue edit <number> --repo <owner/repo> --title <title> --body-file <file>`
- Add labels: `gh issue edit <number> --repo <owner/repo> --add-label <label>`
- Remove labels: `gh issue edit <number> --repo <owner/repo> --remove-label <label>`
- Add assignees: `gh issue edit <number> --repo <owner/repo> --add-assignee <login>`
- Remove assignees: `gh issue edit <number> --repo <owner/repo> --remove-assignee <login>`
- Set milestone: `gh issue edit <number> --repo <owner/repo> --milestone <milestone>`
- Close issue: `gh issue close <number> --repo <owner/repo>`
- Reopen issue: `gh issue reopen <number> --repo <owner/repo>`
- Create draft PR: `gh pr create --draft --base <base> --head <branch> --title <title> --body-file <file>`
- Create ready PR: `gh pr create --base <base> --head <branch> --title <title> --body-file <file>`
- Edit title/body: `gh pr edit <number> --title <title> --body-file <file>`
- Mark ready: `gh pr ready <number>`
- Checkout PR: `gh pr checkout <number>`

Prefer `--body-file` over generated inline bodies when the repo has an issue or PR template.

## CI And Runs

When an installed or repo-local helper is available, prefer it for CI watch data:

```bash
scripts/git/gh/get-ci.sh --repo <owner/repo> --target-type branch --target <branch>
scripts/git/gh/get-ci.sh --repo <owner/repo> --target-type pr --target <number>
scripts/git/gh/get-ci.sh --repo <owner/repo> --target-type run --target <run-id>
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
