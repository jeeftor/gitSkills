# Git Skill Matrix

```mermaid
flowchart TD
    WORKFLOW["$git-workflow<br/>Route Git work"]
    ISSUE_TABLE["$git-issue-table<br/>Summarize issues"]
    ISSUE_DETAILS["$git-issue-details<br/>Inspect one issue"]
    ISSUE_CREATE["$git-issue-create<br/>Create issues"]
    BRANCH_SYNC["$git-branch-sync<br/>Sync branches"]
    PR["$git-pr<br/>Route PR and MR work"]
    PR_TABLE["$git-pr-table<br/>Summarize PRs and MRs"]
    PR_WATCHER["$git-pr-watcher<br/>Inspect one PR or MR"]
    PR_REVIEW["$git-pr-review<br/>Review one PR or MR"]
    PR_ADDRESS["$git-pr-address-comments<br/>Address review feedback"]
    CI_WATCH["$git-ci-watch<br/>Watch CI"]
    PR_CREATE["$git-pr-create<br/>Create a PR or MR<br/>with clear descriptions"]
    PR_UPDATE["$git-pr-update<br/>Update a PR or MR"]
    PR_MERGE["$git-pr-merge<br/>Merge a PR or MR"]

    WORKFLOW --> ISSUE_TABLE
    WORKFLOW --> ISSUE_DETAILS
    WORKFLOW --> ISSUE_CREATE
    WORKFLOW --> BRANCH_SYNC
    WORKFLOW --> PR
    WORKFLOW --> CI_WATCH
    ISSUE_TABLE --> ISSUE_DETAILS
    PR --> PR_TABLE
    PR --> PR_WATCHER
    PR --> PR_REVIEW
    PR --> PR_ADDRESS
    PR --> CI_WATCH
    PR --> PR_CREATE
    PR --> PR_UPDATE
    PR --> PR_MERGE
    PR_TABLE --> PR_WATCHER
    PR_REVIEW --> PR_ADDRESS
    PR_WATCHER --> CI_WATCH
    PR_WATCHER --> PR_ADDRESS
    PR_ADDRESS --> PR_UPDATE
    PR_CREATE --> PR_WATCHER
    PR_CREATE --> CI_WATCH
    PR_UPDATE --> CI_WATCH
    PR_UPDATE --> PR_WATCHER
    PR_WATCHER --> PR_MERGE
```

Read-only overview skills should run before mutating create, update, or merge workflows when the target item is ambiguous.
`$git-issue-table` uses `scripts/git/get-issues.sh` for the common scripted issue collection path.
`$git-issue-details` uses `scripts/git/get-issue.sh` for the common scripted issue detail path before recommending next actions.
`$git-branch-sync` uses `scripts/git/get-branch-state.sh` before recommending or performing branch sync mutations.
`$git-pr-table` uses `scripts/git/get-prs.sh` for the common scripted PR/MR collection path before handing one selected item to `$git-pr-watcher`.
`$git-pr-watcher` uses `scripts/git/get-pr.sh` for the common scripted PR/MR detail path before recommending next actions.
`$git-pr-review` uses `scripts/git/get-pr.sh` for initial status context before diff inspection and findings.
Use `$git-ci-watch` instead of `$git-pr-watcher` when the user only asks about CI for the latest push, branch, commit, run, pipeline, PR, or MR.
`$git-ci-watch` uses `scripts/git/get-ci.sh` for common scripted CI target resolution before provider-specific collection.
