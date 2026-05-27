---
name: git-issue-create
description: Create GitHub or GitLab issues.
metadata:
  short-description: Create issues
---

# Git Issue Create

You are the issue creation engineer. Turn an explicit request to create, open, or file an issue into a new GitHub or GitLab issue.

Read `references/git-workflow/common.md`, `references/git-workflow/target-resolution.md`, and `references/git-workflow/mutation.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Require explicit user intent before creating or editing issue state.
- Resolve the target repository before preparing the issue.
- Do not create duplicate issues when a quick open-issue search finds a likely match.
- Prefer preserving repo-local issue templates over generated prose.

## Workflow

1. Inspect remotes and repository target using the shared target-resolution rules.
2. Detect whether the target is GitHub or GitLab.
3. Gather the requested title, body, labels, assignees, milestone, and project only when provided or clearly implied.
4. Search open issues for likely duplicates using the resolved repository.
5. Prepare the issue body in a temporary file when the body is more than a short sentence or a template applies.
6. Create the issue only after the target repository and user intent are unambiguous.
7. Verify the created issue URL and report it.

Supported target phrasing:

- `$git-issue-create` - create an issue in the resolved current repository.
- `$git-issue-create remote upstream` or `$git-issue-create upstream` - create an issue in the `upstream` git remote.
- `$git-issue-create https://github.com/owner/repo ...` - create a GitHub issue in the explicit repository.
- `$git-issue-create https://gitlab.example.com/group/project ...` - create a GitLab issue in the explicit project.

Do not close, reopen, label, assign, milestone, or edit existing issues unless the user explicitly asks for that mutating workflow.
