# Git Workflow Common Reference

Use this reference for GitHub pull requests and GitLab merge requests.

## Host Detection

Prefer explicit user input first:

1. User-provided GitHub or GitLab URL.
2. `git remote get-url origin`.
3. `git remote get-url upstream`.
4. Repository markers such as `.github/` or `.gitlab-ci.yml`.
5. Available authenticated CLI: `gh auth status` or `glab auth status`.

If detection is still ambiguous, ask before using a platform-specific command.

## Shared Status Terms

- `CI`: passing, failing, pending, missing, or unknown.
- `Review`: approved, changes requested, review required, or unknown.
- `Merge`: mergeable, blocked, conflict, behind, or unknown.
- `Main blocker`: the shortest actionable reason work cannot proceed.

## Safety

- Inspect current branch, remotes, dirty state, and target PR or MR before mutating anything.
- Do not commit, push, rebase, close, or merge unless the user asked for that mutating workflow.
- Stop before destructive branch operations or ambiguous target selection.
- Prefer platform CLIs for read operations, then API calls when summary fields are missing.

