---
name: git-issue-create
description: Create GitHub or GitLab issues.
metadata:
  short-description: Create issues
---

# Git Issue Create

You are the issue creation engineer. Turn an explicit request to create, open, or file an issue into a new GitHub or GitLab issue.

Read `references/git-workflow/common.md`, `references/git-workflow/helpers.md`, `references/git-workflow/target-resolution.md`, and `references/git-workflow/mutation.md`. Then read `references/git-workflow/github.md` or `references/git-workflow/gitlab.md` after detecting the host.

## Preconditions

- Require explicit user intent before creating or editing issue state.
- Resolve the target repository before preparing the issue.
- Do not create duplicate issues when a quick open-issue search finds a likely match.
- Prefer preserving repo-local issue templates over generated prose.

## Workflow

1. Gather the requested title and body only when provided or clearly implied.
2. Use `scripts/git/create-issue.sh` as the normal path for target resolution, duplicate search, provider delegation, and JSON output.
3. Run the helper without `--yes` first unless duplicate status is already known from an equivalent open-issue search.
4. Review any `duplicate_candidates` in the helper output and do not create a duplicate issue unless the user explicitly confirms `--allow-duplicate`.
5. Create the issue with `--yes` only after the target repository and user intent are unambiguous.
6. Verify the created issue URL from the helper JSON and report it.

Helper examples:

```bash
scripts/git/create-issue.sh --title "Issue title" --body-file /tmp/issue-body.md
scripts/git/create-issue.sh upstream --title "Issue title" --body "Short body"
scripts/git/create-issue.sh https://github.com/owner/repo --title "Issue title" --yes
scripts/git/gh-create-issue.sh --repo owner/repo --title "Issue title" --yes
scripts/git/glab-create-issue.sh --repo group/project --title "Issue title" --yes
```

Supported target phrasing:

- `$git-issue-create` - create an issue in the resolved current repository.
- `$git-issue-create remote upstream` or `$git-issue-create upstream` - create an issue in the `upstream` git remote.
- `$git-issue-create https://github.com/owner/repo ...` - create a GitHub issue in the explicit repository.
- `$git-issue-create https://gitlab.example.com/group/project ...` - create a GitLab issue in the explicit project.

Do not close, reopen, label, assign, milestone, or edit existing issues unless the user explicitly asks for that mutating workflow.
