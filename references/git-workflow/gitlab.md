# GitLab Workflow Reference

Use this reference when remotes, URLs, or user input identify GitLab.

## Commands

- Current user: `glab api user`
- Repo/project info: `glab repo view`
- List MRs: `glab mr list`
- Current branch MR: `glab mr view`
- View MR: `glab mr view <iid>`
- Branch MR fallback: `glab mr list --source-branch <branch>`
- MR checks and pipeline details: `glab pipeline list` and `glab pipeline view`
- List issues: `glab issue list`

Use the GitLab API when approval status, discussions, merge train state, or pipeline details are missing from `glab`.

## Create And Update

- Create draft MR: `glab mr create --draft --source-branch <branch> --target-branch <base> --title <title> --description-file <file>`
- Create ready MR: `glab mr create --source-branch <branch> --target-branch <base> --title <title> --description-file <file>`
- Edit MR: `glab mr update <iid>`
- Checkout MR: `glab mr checkout <iid>`

Prefer file-backed descriptions when the repo has a merge request template.

## CI And Pipelines

- Pipelines for branch: `glab pipeline list --branch <branch>`
- Pipeline details: `glab pipeline view <pipeline-id>`
- Job logs: use `glab ci view` or GitLab API when `glab pipeline view` is insufficient.
- Retry jobs or pipelines only when explicitly asked and the target is unambiguous.

Treat missing pipeline data as unknown. Include downstream or merge-train pipeline state when exposed.

## Review, Approvals, And Discussions

- MR summary: `glab mr view <iid>`
- MR diff: `glab mr diff <iid>`
- Use GitLab API for discussions, notes, unresolved threads, approval state, and merge train state when `glab` lacks fields.

Do not resolve discussions, approve, or edit MR text from read-only watcher/table workflows.

## Merge

- Merge: `glab mr merge <iid>`
- Squash or remove source branch only when requested or repo policy clearly requires it.
- Merge train behavior may require GitLab API or project-specific policy checks.

Confirm merge method and squash/source-branch behavior when policy is unclear.

## Merge Request Notes

GitLab merge requests can have draft state, approvals, discussions, pipelines, merge trains, squash settings, and branch protection. If the user says "GitLab PR", treat that as a merge request.
