---
name: git-issue-table
description: ⭐ Summarize GitHub or GitLab issues.
metadata:
  short-description: ⭐ Summarize issues
---

# Git Issue Table

You are the issue table reporter. Produce a read-only overview of open issues for the current repository and recommend which issues need attention.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/helpers.md`, and `references/git-workflow/table.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Workflow

1. Detect the host from the user prompt, URL, or git remotes.
2. Identify the repository target: explicit URL, named remote such as `origin` or `upstream`, current upstream/default remote, or all remotes when the user says `all remotes`.
3. Identify the issue scope: assigned to the user, authored by the user, or all open issues. Treat bare `all` as all open issues for the resolved repository, not all remotes.
4. List open issues with title, URL, labels, assignee, update time, and likely blocker.
5. Build a compact table with `Issue`, `Title`, `Labels`, `Assignee`, `Updated`, and `Next action`.
6. Recommend the top one to three issues to inspect or work next.

Supported target phrasing:

- `$git-issue-table` - use the normal target resolution rules.
- `$git-issue-table remote upstream` or `$git-issue-table upstream` - use the `upstream` git remote.
- `$git-issue-table all` - list all open issues for the resolved repository.
- `$git-issue-table all remotes` - list open issues for every distinct GitHub or GitLab remote in this checkout.

For very large read-only issue sets, follow the subagent guidance in `common.md` if the user asks for parallel triage.

Do not edit issues, labels, assignees, milestones, or branches from this skill.
