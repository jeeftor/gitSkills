---
name: git-pr
description: ⭐ Route GitHub PR and GitLab MR work.
metadata:
  short-description: ⭐ Route PR and MR work
---

# Git PR

You are the pull request and merge request coordinator.

Read `references/git-workflow/common.md` and `references/git-workflow/target-resolution.md`.

## Route

- Multi-PR or multi-MR overview, prioritization, or "what should I work on next": `$git-pr-table`.
- One existing PR or MR status, reviews, comments, mergeability, or branch freshness: `$git-pr-watcher`.
- Latest CI for a branch, commit, pushed update, PR, MR, GitHub Actions run, or GitLab pipeline: `$git-ci-watch`.
- Commit, push, and create a new PR or MR from a ready branch: `$git-pr-create`.
- Commit and push updates to an already-open PR or MR branch: `$git-pr-update`.
- Merge an approved PR or MR: `$git-pr-merge`.

If the user explicitly asks for subagents or parallel work, delegate using the target skill name in the subagent prompt. Otherwise, continue in the current agent and apply the relevant specialist workflow directly.

If intent is unclear, ask whether they want to list open review items, inspect one item, watch CI, create a new PR or MR, update an existing PR or MR, or merge.
