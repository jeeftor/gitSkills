---
name: git-pr-create
description: Create a GitHub PR or GitLab MR.
metadata:
  short-description: Create PRs and MRs
---

# Git PR Create

You are the pull request and merge request creation engineer. Turn ready local branch changes into a new review item.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/mutation.md`, and `references/git-workflow/commit.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Do not create from a default branch unless the user explicitly requests it.
- Do not create a duplicate item when the current branch already has an open PR or MR.
- Do not commit, push, or create when verification is failing unless the user explicitly accepts that status.

## Workflow

1. Inspect branch, remotes, staged files, unstaged files, untracked files, and upstream state.
2. Confirm no open PR or MR already exists for the branch.
3. Confirm the staged files are intended.
4. Run or confirm the narrowest practical verification.
5. Commit staged changes when needed.
6. Push the branch to the appropriate remote.
7. Create a draft PR or draft MR unless the user asks for ready-for-review.
8. Verify the URL and state before reporting success.

## Description Shape

Prefer preserving project templates and repo-local contribution guidance over generated prose. Fill required template sections instead of deleting them, and keep contribution checklist wording intact unless the local instructions say otherwise.

Keep simple PRs and MRs concise. Use short prose or bullets when the change has only a few related facts and a table would add visual noise.

Use Markdown tables when dense structured details are clearer as rows and columns, especially for:

- verification results
- affected areas or components
- compatibility, platform, or migration status
- follow-up work or rollout items

Make tables render cleanly on GitHub and GitLab:

- Put a blank line before and after each table.
- Use a normal header and separator row, such as `| Check | Result | Notes |` followed by `| --- | --- | --- |`.
- Keep cells short; move long reasoning below the table.
- Avoid multiline cells, nested lists, and raw full URLs in table cells.
- Escape literal pipe characters in cells as `\|`.

Examples:

```markdown
| Check | Result | Notes |
| --- | --- | --- |
| `make validate` | Pass | Validates skill metadata and shell syntax. |
| Manual PR preview | Pass | Table renders on GitHub and GitLab. |
```

```markdown
| Area | Change | Impact |
| --- | --- | --- |
| PR description | Adds table guidance | Clearer dense review context. |
| Templates | Preserved | Existing project requirements remain intact. |
```

```markdown
| Platform | Status | Notes |
| --- | --- | --- |
| GitHub | Supported | Standard Markdown tables render in PR bodies. |
| GitLab | Supported | Standard Markdown tables render in MR descriptions. |
```

```markdown
| Follow-up | Owner | Timing |
| --- | --- | --- |
| Watch CI | Author | After push |
| Address review comments | Author | During review |
```
