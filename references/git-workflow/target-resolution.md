# Git Target Resolution Reference

Use this reference when a skill must identify the host, repository, branch, issue, PR, MR, commit, run, job, or pipeline.

## Host Resolution

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

## Mixed GitHub And GitLab Repos

- Explicit user intent wins over remotes.
- Branch upstream wins over generic repo markers.
- For read-only overviews, report both platforms only when the user asks for both or the repo clearly uses both.
- For mutating actions, ask before creating, updating, rerunning, canceling, pushing, approving, or merging on a platform that is not unambiguous.
- For CI-only requests, choose the CI platform named by the user. If both GitHub Actions and GitLab pipelines are available and the user asks for "latest CI", ask which one unless the branch upstream or URL makes it clear.

## Local Commands

- Current branch: `git branch --show-current`
- Current branch upstream: `git rev-parse --abbrev-ref --symbolic-full-name @{u}`
- Current commit: `git rev-parse HEAD`
- Local status: `git status --short --branch`
- Origin URL: `git remote get-url origin`
- Upstream URL: `git remote get-url upstream`
- All remotes: `git remote -v`
- Default branch candidates: inspect remote HEAD with `git remote show <remote>` when needed.

## PR/MR Lookup

Prefer the platform CLI after host detection:

- GitHub current branch PR: `gh pr view --json number,title,url,headRefName,baseRefName,state,isDraft`
- GitHub branch PR fallback: `gh pr list --head <branch> --state open --json number,title,url,headRefName,baseRefName,isDraft`
- GitLab current branch MR: `glab mr view`
- GitLab branch MR fallback: `glab mr list --source-branch <branch>`

If more than one open PR/MR matches, ask before mutating.

## Issue Lookup

Resolve issues from explicit URL or number first. If the user asks for a table, use the authenticated user scope only when requested or when it is the obvious intent.

## CI Target Lookup

Resolve CI targets in this order:

1. Explicit run, pipeline, job, URL, PR, MR, or commit SHA.
2. The PR or MR associated with the current branch.
3. The latest pushed commit on the current branch.
4. The current local `HEAD` commit, clearly labeled as local if it has not been pushed.
