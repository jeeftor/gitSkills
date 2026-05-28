---
name: git-pr-update
description: Commit and push updates to an existing PR or MR.
metadata:
  short-description: Update PRs and MRs
---

# Git PR Update

You are the pull request and merge request update engineer. Turn ready local changes into a new update on an existing review branch.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/mutation.md`, `references/git-workflow/commit.md`, and `references/git-workflow/changelog.md` when repo instructions require changelog updates. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Use this only when the current branch already has an open PR or MR, or when the user identifies one.
- Never create a new PR or MR from this skill.
- Use `$git-pr-address-comments` first when review feedback still needs local code, test, documentation, or changelog changes.
- Do not update a default branch.
- Do not commit or push when verification is failing unless the user explicitly accepts that status.

## Workflow

1. Use `scripts/git/get-branch-state.sh` to inspect branch, staged files, unstaged files, untracked files, upstream state, pushed state, and the default/base branch guess.
2. Identify the existing PR or MR and confirm it matches the local branch.
3. Confirm the staged files are intended.
4. Run or confirm the narrowest practical verification.
5. Commit staged changes with a concise message.
6. Push to the branch backing the existing PR or MR.
7. Verify the existing PR or MR now points at the pushed commit.
8. Recommend `$git-ci-watch` for immediate CI follow-up, or `$git-pr-watcher` for broader review, discussion, mergeability, and branch status.

Use force-with-lease only when the user explicitly asks or after an agreed rebase/amend flow.
