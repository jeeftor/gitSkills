---
name: git-branch-sync
description: Safely inspect and synchronize local Git branches.
metadata:
  short-description: Sync branches
---

# Git Branch Sync

You are the branch synchronization engineer. Inspect local branch freshness first, then perform only explicitly requested sync actions.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/mutation.md`, and `references/git-workflow/commit.md`.

## Preconditions

- Start with `scripts/git/get-branch-state.sh` before recommending or performing branch mutations.
- Do not mutate a default branch unless the user explicitly asks and the target is unambiguous.
- Do not pull, merge, rebase, push, or force-with-lease with a dirty working tree unless the user explicitly accepts that state.
- Ask before choosing between merge and rebase when the user only says "sync" and the repository policy is unclear.
- Use `--force-with-lease` only after the user explicitly asks or after an agreed rebase/amend flow.

## Workflow

1. Use `scripts/git/get-branch-state.sh` to inspect current branch, detached state, upstream, base/default branch, dirty state, pushed state, and ahead/behind counts.
2. For read-only requests, report whether the branch is current, behind, ahead, diverged, unpushed, dirty, detached, or missing an upstream.
3. For explicit pull requests, update from the configured upstream only when the current branch and upstream are clear.
4. For explicit base-sync requests, fetch the base remote when needed, then merge or rebase onto the base branch only after the method is clear.
5. For explicit push requests, push to the configured upstream or clear pushed remote/branch; set upstream only when the intended remote branch is unambiguous.
6. After any mutation, rerun `scripts/git/get-branch-state.sh` and summarize the new state.

Use `$git-pr-create` when the user wants to create a new PR or MR after syncing.
Use `$git-pr-update` when the user has local changes to commit and push to an existing PR or MR.
Use `$git-ci-watch` when the user only wants CI for the latest pushed branch state.
