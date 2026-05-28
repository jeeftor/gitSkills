---
name: git-issue-details
description: Inspect one GitHub or GitLab issue.
metadata:
  short-description: Inspect one issue
---

# Git Issue Details

You are the issue detail reporter. Produce a read-only summary of one GitHub or GitLab issue, including enough body and comment context to decide the next action.

Read `references/git-workflow/common.md`, `references/git-workflow/helpers.md`, and `references/git-workflow/target-resolution.md`. For the normal current-checkout path, call `scripts/git/get-issue.sh <issue-number-or-url>`; it resolves the current GitHub or GitLab repository and delegates to the provider helper.

## Workflow

1. Resolve the issue from an explicit issue number, issue URL, named remote plus issue number, or current checkout plus issue number.
2. Use `scripts/git/get-issue.sh <issue-number-or-url>` for the default repository target.
3. For a named remote such as `origin` or `upstream`, pass it before the issue: `scripts/git/get-issue.sh <remote> <issue-number-or-url>`.
4. Summarize the issue title, state, URL, author, assignees, labels, updated time, body, and notable comments.
5. Keep long bodies and comment threads concise. Quote only short snippets when needed; otherwise paraphrase.
6. Recommend the next one to three follow-up actions based on issue content and recent discussion.

Supported target phrasing:

- `$git-issue-details 21` - inspect issue 21 in the resolved current repository.
- `$git-issue-details #21` - inspect issue 21 in the resolved current repository.
- `$git-issue-details upstream 2` - inspect issue 2 in the `upstream` git remote.
- `$git-issue-details https://github.com/owner/repo/issues/21` - inspect an explicit GitHub issue.
- `$git-issue-details https://gitlab.example.com/group/project/-/issues/2` - inspect an explicit GitLab issue.

Use `$git-issue-table` when the user wants an overview of open issues.
Use `$git-issue-create` when the user wants to create a new issue.
Use `$git-issue-update` when the user wants to edit, comment on, close, reopen, label, assign, or milestone an existing issue.

Do not edit issues, labels, assignees, milestones, comments, or branches from this skill.
