---
name: git-issue-table
description: ⭐ Summarize GitHub or GitLab issues.
metadata:
  short-description: ⭐ Summarize issues
---

# Git Issue Table

You are the issue table reporter. Produce a read-only overview of open issues for the current repository and recommend which issues need attention.

Read `references/git-workflow/common.md`, `references/git-workflow/helpers.md`, and `references/git-workflow/table.md`. For the normal current-checkout path, call `scripts/git/get-issues.sh --state open --limit 50`; it resolves the current GitHub or GitLab repository and delegates to the provider helper. Read `references/git-workflow/target-resolution.md` only when the user names a URL, named remote, issue scope, or multi-remote target that the helper cannot resolve directly.

## Workflow

1. Use `scripts/git/get-issues.sh --state open --limit 50` for the default repository target.
2. For a named remote such as `origin` or `upstream`, pass it to the helper as the target: `scripts/git/get-issues.sh <remote> --state open --limit 50`.
3. Identify the issue scope: assigned to the user, authored by the user, or all open issues. Treat bare `all` as all open issues for the resolved repository, not all remotes.
4. List open issues with title, URL, and update age.
5. Build a Markdown table with `Issue`, `Title`, and `Updated`. Do not include labels, owner, work, or a generic `Next action` column for normal issue lists; put recommendations after the table.
6. Prioritize the `Title` column.
7. Format `Updated` as a compact relative age such as `2h ago`, `1d ago`, or `3mo ago` when possible. Use an exact date only when relative age would be unclear.
8. Recommend the top one to three issues to inspect or work next based on recency, title relevance, and explicit user context.

Supported target phrasing:

- `$git-issue-table` - use the normal target resolution rules.
- `$git-issue-table remote upstream` or `$git-issue-table upstream` - use the `upstream` git remote.
- `$git-issue-table all` - list all open issues for the resolved repository.
- `$git-issue-table all remotes` - list open issues for every distinct GitHub or GitLab remote in this checkout.

For very large read-only issue sets, follow the subagent guidance in `common.md` if the user asks for parallel triage.

Do not edit issues, labels, assignees, milestones, or branches from this skill.
