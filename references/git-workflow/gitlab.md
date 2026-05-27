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

## Merge Requests

When an installed or repo-local helper is available, prefer it for MR table data:

```bash
scripts/git/glab-get-mrs.sh --repo <group/project> --state opened --scope all --limit 50
```

Use `--scope authored`, `--scope assigned`, or `--scope review` when the user asks for MRs they authored, MRs assigned to them, or MRs needing their review.

The helper emits normalized JSON for table summaries, including draft state, reviewers, merge state, branches, discussion status, and head-pipeline fields.

Fallback commands:

- List MRs: `glab mr list --repo <group/project> --output json --per-page 50`
- MR API: `glab api projects/<url-encoded-project-path>/merge_requests`

## Issues

When an installed or repo-local helper is available, prefer it for issue table data:

```bash
scripts/git/get-issues.sh <gitlab-remote> --state open --limit 50
scripts/git/glab-get-issues.sh --repo <group/project> --state opened --limit 50
```

The generic helper resolves named GitLab remotes before delegating to the GitLab helper. The GitLab helper emits normalized JSON and includes REST fields that are awkward to extract from `glab issue list`, including task completion and blocking issue metadata.

Fallback commands:

- List issues: `glab issue list --repo <group/project> --opened --output json --per-page 50`
- Issue API: `glab api projects/<url-encoded-project-path>/issues`

## Create And Update

- Create issue: `glab issue create --repo <group/project> --title <title> --description <description> --yes`
- Create draft MR: `glab mr create --draft --source-branch <branch> --target-branch <base> --title <title> --description-file <file>`
- Create ready MR: `glab mr create --source-branch <branch> --target-branch <base> --title <title> --description-file <file>`
- Edit MR: `glab mr update <iid>`
- Checkout MR: `glab mr checkout <iid>`

Prefer file-backed descriptions when the repo has a merge request template. For issue bodies, prepare the description in a temporary file first when the body is too long to quote safely.

## CI And Pipelines

When an installed or repo-local helper is available, prefer it for CI watch data:

```bash
scripts/git/glab-get-ci.sh --repo <group/project> --target-type branch --target <branch>
scripts/git/glab-get-ci.sh --repo <group/project> --target-type mr --target <iid>
scripts/git/glab-get-ci.sh --repo <group/project> --target-type pipeline --target <pipeline-id>
```

The helper emits normalized JSON for summaries, including status, jobs, failed logs, URL, commit, and branch fields.

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
