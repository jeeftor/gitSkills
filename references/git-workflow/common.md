# Git Workflow Common Reference

Use this reference for GitHub pull requests and GitLab merge requests.

## Host And Target Detection

Do not assume `origin` is the only source of truth. Some repositories mirror between GitHub and GitLab, use GitHub for source and GitLab for CI, or keep multiple remotes.

Resolve the target platform in this order:

1. Explicit user input: platform name, GitHub URL, GitLab URL, PR URL, MR URL, issue URL, run URL, or pipeline URL.
2. Current task language:
   - `pull request`, `PR`, GitHub Actions, check suite, workflow run -> prefer GitHub.
   - `merge request`, `MR`, GitLab pipeline, job, merge train -> prefer GitLab.
   - Treat "GitLab PR" as a GitLab merge request.
3. The current branch upstream from `git rev-parse --abbrev-ref --symbolic-full-name @{u}` when it exists.
4. `git remote get-url origin`.
5. `git remote get-url upstream`.
6. All remotes from `git remote -v` when origin and upstream are inconclusive.
7. Repository markers:
   - `.github/` suggests GitHub.
   - `.gitlab-ci.yml` suggests GitLab.
8. Available authenticated CLI:
   - `gh auth status`
   - `glab auth status`

If detection is still ambiguous, ask before using a platform-specific command.

When both GitHub and GitLab are present:

- Explicit user intent wins over remotes.
- Branch upstream wins over generic repo markers.
- For read-only overviews, report both platforms only when the user asks for both or the repo clearly uses both.
- For mutating actions, ask before creating, updating, rerunning, canceling, pushing, approving, or merging on a platform that is not unambiguous.
- For CI-only requests, choose the CI platform named by the user. If both GitHub Actions and GitLab pipelines are available and the user asks for "latest CI", ask which one unless the branch upstream or URL makes it clear.

Useful local commands:

- Current branch: `git branch --show-current`
- Current branch upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{u}`
- Origin URL: `git remote get-url origin`
- Upstream URL: `git remote get-url upstream`
- All remotes: `git remote -v`

## Shared Status Terms

- `CI`: passing, failing, pending, missing, or unknown.
- `Review`: approved, changes requested, review required, or unknown.
- `Merge`: mergeable, blocked, conflict, behind, or unknown.
- `Main blocker`: the shortest actionable reason work cannot proceed.

## Safety

- Inspect current branch, remotes, dirty state, and target PR or MR before mutating anything.
- Respect the repository's `.gitignore`. Do not stage ignored files or local-only artifacts unless the user explicitly asks.
- Never blindly stage everything. Do not run `git add -A`, `git add .`, `git commit -a`, or broad equivalent staging commands unless the user explicitly asks for that exact behavior after seeing the file list.
- Prefer path-specific `git add <file>` for intended files after reviewing `git status --short`.
- Do not commit, push, rebase, close, or merge unless the user asked for that mutating workflow.
- Stop before destructive branch operations or ambiguous target selection.
- Prefer platform CLIs for read operations, then API calls when summary fields are missing.

## Subagents And Parallel Work

Use subagents only when the user explicitly asks for subagents, delegation, or parallel work, or when a read-only investigation is large enough that splitting evidence is clearly useful.

Good subagent tasks:

- Split a long PR/MR list into non-overlapping groups for summary fields and blockers.
- Inspect CI logs while the main agent inspects review comments and discussions.
- Inspect GitHub and GitLab signals separately when a repo legitimately uses both.
- Compare branch freshness, conflicts, and mergeability while another read-only pass reviews comments.

Keep final prioritization, decisions, and user-facing recommendations in the main agent. Do not delegate commits, pushes, rebases, force pushes, merges, branch deletion, PR/MR edits, issue edits, CI reruns, or CI cancellations.

When using subagents, give each one:

- the target skill name
- the exact repo, PR/MR, issue, run, pipeline, branch, or commit to inspect
- a read-only scope
- the fields to report back

Do not run parallel agents in the same working tree when they may edit files or branch state.
