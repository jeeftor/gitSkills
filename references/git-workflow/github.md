# GitHub Workflow Reference

Use this reference when remotes, URLs, or user input identify GitHub.

## Commands

- Current user: `gh api user --jq .login`
- List PRs: `gh pr list --json number,title,url,isDraft,mergeStateStatus,reviewDecision,statusCheckRollup,updatedAt,headRefName,baseRefName`
- View PR: `gh pr view <number> --json number,title,url,isDraft,mergeStateStatus,reviewDecision,reviews,comments,statusCheckRollup,updatedAt`
- PR checks: `gh pr checks <number>`
- List issues: `gh issue list --json number,title,url,state,labels,assignees,updatedAt`

Use GraphQL when unresolved review thread counts or mergeability details are missing from `gh pr view`.

## Pull Request Notes

GitHub pull requests can have draft state, review decisions, checks, review threads, merge queues, and branch protection. Treat missing fields as unknown rather than successful.

