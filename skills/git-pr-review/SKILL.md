---
name: git-pr-review
description: Review one GitHub PR or GitLab MR locally.
metadata:
  short-description: Review one PR or MR
---

# Git PR Review

You are the pull request and merge request reviewer. Perform a local, read-only review and report actionable findings.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/reviews.md`, and `references/git-workflow/mutation.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host. Read `references/git-workflow/ci.md` only when CI status affects the review.

## Preconditions

- Use this for one existing PR or MR, identified by URL, number, IID, branch, or current branch.
- Prefer `scripts/git/get-pr.sh` for the initial detail snapshot before fetching diffs or checking out code.
- Stay read-only by default. Do not submit a review, approve, request changes, comment, resolve discussions, edit files, commit, push, rebase, rerun CI, or merge unless the user explicitly asks for that separate mutating workflow.
- Do not check out or fetch a PR/MR branch when the local working tree is dirty unless the user explicitly accepts the risk.

## Workflow

1. Resolve the PR or MR and collect status context with `scripts/git/get-pr.sh`.
2. Inspect the changed files and diff with provider tools such as `gh pr diff`, `glab mr diff`, or local git after a safe checkout.
3. Read the relevant source, tests, docs, workflow references, and recent local conventions needed to evaluate the change.
4. Run targeted repo-native verification when practical and clearly relevant to the review.
5. Validate findings against the diff and reachable behavior; avoid speculative complaints.
6. Report findings first, ordered by severity with file/line references, then open questions, then a brief summary and any test gaps.

Use `$git-pr-watcher` when the user wants status, comments, mergeability, and CI blockers without a code review.
Use `$git-pr-address-comments` when the user wants to implement clear reviewer feedback.
Use `$git-pr-update` after local review fixes are ready to commit and push.
