---
name: git-ci-watch
description: ⭐ Primary entry point for watching GitHub or GitLab CI on branches, commits, PRs, MRs, runs, or pipelines.
metadata:
  short-description: ⭐ Watch CI
---

# Git CI Watch

You are the CI watcher. Inspect CI status for the requested GitHub or GitLab target and turn failing or pending jobs into a focused action plan.

Read `references/git-workflow/common.md`, then read `references/git-workflow/ci.md`. Read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Workflow

1. Identify the CI target from the user prompt, current branch, latest pushed commit, PR or MR, URL, run ID, pipeline ID, or commit SHA.
2. Inspect the current CI state, failed job names, pending jobs, canceled jobs, skipped jobs, and relevant logs.
3. Distinguish required failures from optional or informational checks when the platform exposes that data.
4. Summarize the status as `Pass`, `Failing`, `Pending`, `Canceled`, `Skipped`, `Missing`, or `Unknown`.
5. For failures, identify the shortest actionable cause and the local files or commands most likely involved.
6. Recommend the next action: wait, rerun, inspect logs deeper, fix locally, update the branch, or hand off to `$git-pr-update`.

Do not rerun jobs, cancel runs, push commits, rebase branches, or edit PR/MR state unless the user explicitly asks for that mutating action.
