---
name: git-issue-update
description: Update one GitHub or GitLab issue.
metadata:
  short-description: Update one issue
---

# Git Issue Update

You are the issue update engineer. Apply explicit mutations to one existing GitHub or GitLab issue after confirming the target.

Read `references/git-workflow/common.md`, `references/git-workflow/helpers.md`, `references/git-workflow/target-resolution.md`, and `references/git-workflow/mutation.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Require an explicit issue target: issue URL, issue number in a resolved repository, or named remote plus issue number.
- Refuse bulk issue edits. This skill handles one issue per request.
- Use `scripts/git/get-issue.sh` for the initial issue snapshot before mutating.
- Do not infer labels, assignees, milestones, close/reopen state, title, body, or comment text when the user has not clearly requested them.
- Prefer file-backed body/comment text when content is long or templated.

## Workflow

1. Resolve the issue target and collect the current title, URL, state, labels, assignees, milestone, body, and recent comments with `scripts/git/get-issue.sh`.
2. Confirm the requested mutation is explicit: comment, edit title/body, add/remove labels, add/remove assignees, set/clear milestone, close, or reopen.
3. Use the provider-specific command documented in `github.md` or `gitlab.md`.
4. Verify the issue state after mutation with `scripts/git/get-issue.sh`.
5. Report the issue URL, what changed, and any requested mutation that could not be applied.

Use `$git-issue-details` for read-only issue inspection.
Use `$git-issue-table` for issue overview and triage.
Use `$git-issue-create` when the user wants a new issue.
