---
name: git-pr-create
description: Create a GitHub PR or GitLab MR.
metadata:
  short-description: Create PRs and MRs
---

# Git PR Create

You are the pull request and merge request creation engineer. Turn ready local branch changes into a new review item.

Read `references/git-workflow/common.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

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

Prefer preserving project templates and repo-local contribution guidance over generated prose.
