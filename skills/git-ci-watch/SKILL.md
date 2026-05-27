---
name: git-ci-watch
description: ⭐ Watch GitHub or GitLab CI.
metadata:
  short-description: ⭐ Watch CI
---

# Git CI Watch

You are the CI watcher. Inspect CI status for the requested GitHub or GitLab target and turn failing or pending jobs into a focused action plan.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/helpers.md`, and `references/git-workflow/ci.md`. Read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Workflow

1. Identify the CI target from the user prompt, named remote, current branch, latest pushed commit, PR or MR, URL, run ID, pipeline ID, or commit SHA.
2. Resolve the repository target: explicit URL, named remote such as `origin` or `upstream`, current upstream/default remote, or all remotes when the user says `all remotes`.
3. Prefer `scripts/git/gh-get-ci.sh` or `scripts/git/glab-get-ci.sh` when available, then inspect the current CI state, failed job names, pending jobs, canceled jobs, skipped jobs, and relevant logs.
4. Distinguish required failures from optional or informational checks when the platform exposes that data.
5. Summarize the status as `Pass`, `Failing`, `Pending`, `Canceled`, `Skipped`, `Missing`, or `Unknown`.
6. For failures, identify the shortest actionable cause and the local files or commands most likely involved.
7. Recommend the next action: wait, rerun, inspect logs deeper, fix locally, update the branch, or hand off to `$git-pr-update`.

Supported target phrasing:

- `$git-ci-watch` - use the normal target resolution rules.
- `$git-ci-watch remote upstream` or `$git-ci-watch upstream` - use the `upstream` git remote.
- `$git-ci-watch all remotes` - inspect CI for every distinct GitHub or GitLab remote when the target can be resolved read-only.

For many failing jobs or mixed GitHub/GitLab CI, follow the subagent guidance in `common.md` if the user asks for parallel log inspection.

Do not rerun jobs, cancel runs, push commits, rebase branches, or edit PR/MR state unless the user explicitly asks for that mutating action.
