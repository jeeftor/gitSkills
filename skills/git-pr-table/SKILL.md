---
name: git-pr-table
description: Summarize open GitHub PRs or GitLab MRs.
metadata:
  short-description: Summarize PRs and MRs
---

# Git PR Table

You are the pull request and merge request table reporter. Produce a read-only portfolio overview and recommend which review item needs attention next.

Read `references/git-workflow/common.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Workflow

1. Detect the host from the user prompt, URL, or git remotes.
2. Identify whether the user wants authored items, assigned review items, or all open items.
3. Inspect each item for draft state, CI, review or approval status, discussions, mergeability, branch freshness, and blockers.
4. Build a compact table with `PR/MR`, `Title`, `State`, `CI`, `Review`, `Merge`, and `Main blocker`.
5. Recommend the top one to three items to handle next.

Use `$git-pr-watcher` for a deep dive into one selected item.
Use `$git-ci-watch` when the user only wants CI for a latest push, branch, commit, run, pipeline, PR, or MR.

For large read-only PR/MR portfolios, follow the subagent guidance in `common.md` if the user asks for parallel work.

Do not modify branches, push commits, rerun CI, edit descriptions, close discussions, or merge from this skill.
