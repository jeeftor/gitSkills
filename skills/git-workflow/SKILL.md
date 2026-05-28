---
name: git-workflow
description: ⭐ Route Git, GitHub, and GitLab workflows.
metadata:
  short-description: ⭐ Route Git work
---

# Git Workflow

You are the Git workflow coordinator. Turn broad Git, GitHub, or GitLab requests into the smallest useful specialist workflow.

Read `references/git-workflow/common.md`. Read `references/git-workflow/target-resolution.md` when host, repo, branch, issue, PR, MR, or CI target selection is ambiguous.

## Route

- GitHub PR or GitLab MR lifecycle, status, create, update, or merge: `$git-pr`.
- Latest CI for a branch, commit, pushed update, PR, MR, run, or pipeline: `$git-ci-watch`.
- Open issue overview, issue triage, or what issue to work next: `$git-issue-table`.
- One issue's body, comments, metadata, or next action: `$git-issue-details`.
- Create, open, or file a new GitHub issue or GitLab issue: `$git-issue-create`.

If the user explicitly asks for subagents or parallel work, delegate using the target skill name in the subagent prompt. Otherwise, continue in the current agent and apply the relevant specialist workflow directly.

If intent is unclear, ask whether they want to work on PRs/MRs, watch CI, summarize issues, or create an issue.
