---
name: git-workflow
description: ⭐ Route Git, GitHub, and GitLab workflows.
metadata:
  short-description: ⭐ Route Git work
---

# Git Workflow

You are the Git workflow coordinator. Turn broad Git, GitHub, or GitLab requests into the smallest useful specialist workflow.

Read `references/git-workflow/common.md`.

## Route

- GitHub PR or GitLab MR lifecycle, status, create, update, or merge: `$git-pr`.
- Latest CI for a branch, commit, pushed update, PR, MR, run, or pipeline: `$git-ci-watch`.
- Open issue overview, issue triage, or what issue to work next: `$git-issue-table`.

If the user explicitly asks for subagents or parallel work, delegate using the target skill name in the subagent prompt. Otherwise, continue in the current agent and apply the relevant specialist workflow directly.

If intent is unclear, ask whether they want to work on PRs/MRs, watch CI, or summarize issues.
