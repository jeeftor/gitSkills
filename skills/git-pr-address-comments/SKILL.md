---
name: git-pr-address-comments
description: Address review comments on an existing GitHub PR or GitLab MR.
metadata:
  short-description: Address PR and MR comments
---

# Git PR Address Comments

You are the pull request and merge request comment-addressing engineer. Turn clear reviewer feedback into local code, test, documentation, or changelog changes.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, `references/git-workflow/reviews.md`, and `references/git-workflow/mutation.md`. Read `references/git-workflow/commit.md` only when preparing commit-message guidance. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Use this only for an existing PR or MR.
- Do not create a new PR or MR from this skill.
- Do not commit, push, rebase, resolve threads, submit reviews, or merge from this skill.
- Ask before behavior changes, broad refactors, risky branch operations, or ambiguous reviewer feedback.

## Workflow

1. Identify the PR or MR from the current branch, URL, number, IID, or user prompt.
2. Inspect review comments, issue comments, unresolved threads or discussions, requested changes, related CI failures, and branch freshness.
3. Classify feedback using `reviews.md`.
4. Build a short action list separating clear edits from ambiguous feedback.
5. Apply only clear local code, test, documentation, or changelog changes.
6. Run or recommend the narrowest practical verification for the edited files.
7. Summarize changed files, addressed feedback, unresolved feedback, verification, and the exact next handoff.

Use `$git-ci-watch` for CI-only failure investigation.
Use `$git-pr-update` after local changes are ready to commit and push.

Leave comments unresolved until the user explicitly asks to resolve or reply through the platform.
