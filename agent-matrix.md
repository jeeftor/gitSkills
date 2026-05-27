# Git Skill Matrix

```mermaid
flowchart TD
    WORKFLOW["$git-workflow<br/>Route Git work"]
    ISSUE_TABLE["$git-issue-table<br/>Summarize issues"]
    PR["$git-pr<br/>Route PR and MR work"]
    PR_TABLE["$git-pr-table<br/>Summarize PRs and MRs"]
    PR_WATCHER["$git-pr-watcher<br/>Inspect one PR or MR"]
    PR_ADDRESS["$git-pr-address-comments<br/>Address review feedback"]
    CI_WATCH["$git-ci-watch<br/>Watch CI"]
    PR_CREATE["$git-pr-create<br/>Create a PR or MR<br/>with clear descriptions"]
    PR_UPDATE["$git-pr-update<br/>Update a PR or MR"]
    PR_MERGE["$git-pr-merge<br/>Merge a PR or MR"]

    WORKFLOW --> ISSUE_TABLE
    WORKFLOW --> PR
    WORKFLOW --> CI_WATCH
    PR --> PR_TABLE
    PR --> PR_WATCHER
    PR --> PR_ADDRESS
    PR --> CI_WATCH
    PR --> PR_CREATE
    PR --> PR_UPDATE
    PR --> PR_MERGE
    PR_TABLE --> PR_WATCHER
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
Use `$git-ci-watch` instead of `$git-pr-watcher` when the user only asks about CI for the latest push, branch, commit, run, pipeline, PR, or MR.
