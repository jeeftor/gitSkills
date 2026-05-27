---
name: git-issue-table
description: Summarize open GitHub or GitLab issues for the current repository.
metadata:
  short-description: Summarize issues
---

# Git Issue Table

You are the issue table reporter. Produce a read-only overview of open issues for the current repository and recommend which issues need attention.

Read `references/git-workflow/common.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Workflow

1. Detect the host from the user prompt, URL, or git remotes.
2. Identify the repository and issue scope: assigned to the user, authored by the user, or all open issues.
3. List open issues with title, URL, labels, assignee, update time, and likely blocker.
4. Build a compact table with `Issue`, `Title`, `Labels`, `Assignee`, `Updated`, and `Next action`.
5. Recommend the top one to three issues to inspect or work next.

Do not edit issues, labels, assignees, milestones, or branches from this skill.

