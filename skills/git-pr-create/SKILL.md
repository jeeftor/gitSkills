---
name: git-pr-create
description: Create a GitHub PR or GitLab MR.
metadata:
  short-description: Create PRs and MRs
---

# Git PR Create

You are the pull request and merge request creation engineer. Turn ready local branch changes into a new review item.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/mutation.md`, `references/git-workflow/commit.md`, and `references/git-workflow/changelog.md` when repo instructions require changelog updates. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Do not create from a default branch unless the user explicitly requests it.
- If the current branch is the default branch, create or switch to a non-default feature branch before staging, committing, pushing, or creating the PR/MR.
- If the current branch is a dirty default branch, inspect staged, unstaged, and untracked files before switching; ask when ownership is unclear so unrelated work is not carried onto the PR/MR branch.
- Do not create a duplicate item when the current branch already has an open PR or MR.
- Do not commit, push, or create when verification is failing unless the user explicitly accepts that status.
- Inspect repo-local PR/MR templates before composing the body. Use the only applicable template automatically; ask the user which template to use when multiple templates apply.

## Workflow

1. Use `scripts/git/get-branch-state.sh` to inspect branch, staged files, unstaged files, untracked files, upstream state, pushed state, and the default/base branch guess.
2. When the current branch is the default branch, create or switch to a named feature branch before staging or committing only after dirty files are confirmed to belong to that PR/MR.
3. Confirm no open PR or MR already exists for the branch.
4. Confirm the staged files are intended.
5. Run or confirm the narrowest practical verification.
6. Commit staged changes when needed.
7. Push the branch to the appropriate remote.
8. Inspect the provider template locations in `github.md` or `gitlab.md`, then prepare the body from the selected template when one applies.
9. Create a draft PR or draft MR unless the user asks for ready-for-review.
10. Verify the URL and state before reporting success.

## Description Shape

Prefer preserving project templates and repo-local contribution guidance over generated prose. Fill required template sections instead of deleting them, and keep contribution checklist wording intact unless the local instructions say otherwise.

Keep simple PRs and MRs concise. Use short prose or bullets when the change has only a few related facts and a table would add visual noise. When composing a PR/MR description or when dense description guidance is needed, read `references/git-workflow/pr-description.md`.

Use Markdown tables when dense structured details are clearer as rows and columns, especially for:

- verification results
- affected areas or components
- compatibility, platform, or migration status
- follow-up work or rollout items
