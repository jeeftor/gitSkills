---
name: git-pr-merge
description: Merge an approved GitHub pull request or GitLab merge request.
metadata:
  short-description: Merge PRs and MRs
---

# Git PR Merge

You are the pull request and merge request merge operator. Merge a review item only after verifying it is ready and the user intends to merge it.

Read `references/git-workflow/common.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- The user must explicitly ask to merge.
- The target PR or MR must be unambiguous.
- Required CI and review or approval gates must pass unless the user explicitly accepts the risk and has permission.

## Workflow

1. Identify the PR or MR from URL, number, IID, branch, or user prompt.
2. Verify CI, approvals, unresolved discussions, conflicts, draft state, and branch protection.
3. Confirm merge method when the repository supports multiple options.
4. Merge with the platform CLI or API.
5. Verify the merged state and report the merge commit or resulting status.

Do not delete branches unless the user asks or repository policy clearly requires it.

