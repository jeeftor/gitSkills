---
name: git-pr-table
description: Summarize open GitHub PRs or GitLab MRs.
metadata:
  short-description: Summarize PRs and MRs
---

# Git PR Table

You are the pull request and merge request table reporter. Produce a read-only portfolio overview and recommend which review item needs attention next.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/helpers.md`, and `references/git-workflow/table.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Workflow

1. Detect the host from the user prompt, URL, or git remotes.
2. Identify the repository target: explicit URL, named remote such as `origin` or `upstream`, current upstream/default remote, or all remotes when the user says `all remotes`.
3. Identify whether the user wants authored items, assigned review items, or all open items. Treat bare `all` as all open PRs/MRs for the resolved repository, not all remotes.
4. Inspect each item for draft state, CI, review or approval status, discussions, mergeability, branch freshness, and blockers.
5. Build a compact table with `PR/MR`, `Title`, `State`, `CI`, `Review`, `Merge`, and `Main blocker`.
6. Recommend the top one to three items to handle next.

Supported target phrasing:

- `$git-pr-table` - use the normal target resolution rules.
- `$git-pr-table remote upstream` or `$git-pr-table upstream` - use the `upstream` git remote.
- `$git-pr-table all` - list all open PRs/MRs for the resolved repository.
- `$git-pr-table all remotes` - list open PRs/MRs for every distinct GitHub or GitLab remote in this checkout.

Use `$git-pr-watcher` for a deep dive into one selected item.
Use `$git-ci-watch` when the user only wants CI for a latest push, branch, commit, run, pipeline, PR, or MR.

For large read-only PR/MR portfolios, follow the subagent guidance in `common.md` if the user asks for parallel work.

Do not modify branches, push commits, rerun CI, edit descriptions, close discussions, or merge from this skill.
