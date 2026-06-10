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
- Current issue user: `glab api user`
- List issues: `glab issue list`

Use the GitLab API when approval status, discussions, merge train state, or pipeline details are missing from `glab`.

## Merge Requests

When an installed or repo-local helper is available, prefer it for MR table and detail data:

```bash
scripts/git/get-prs.sh <gitlab-remote> --state open --scope all --limit 50
scripts/git/get-pr.sh <gitlab-remote> --number <iid>
scripts/git/get-pr.sh <gitlab-remote> --branch <branch>
scripts/git/glab/get-mrs.sh --repo <group/project> --state opened --scope all --limit 50
scripts/git/glab/get-mr.sh --repo <group/project> --number <iid>
```

Use `--scope authored`, `--scope assigned`, or `--scope review` when the user asks for MRs they authored, MRs assigned to them, or MRs needing their review.

The generic list helper resolves named GitLab remotes before delegating to the GitLab helper. It keeps normalized list output narrow and emits a table-ready `items` list with draft state, CI status, review status, discussion status, mergeability, branch freshness, URLs, and blocker text. The generic detail helper resolves one MR by URL, IID, or branch and emits description, discussions, approvals, merge state, branches, and pipeline context. GitLab helpers remain available for direct provider-specific collection.

Fallback commands:

- List MRs: `glab mr list --repo <group/project> --output json --per-page 50`
- MR API: `glab api projects/<url-encoded-project-path>/merge_requests`

## Issues

When an installed or repo-local helper is available, prefer it for issue table data:

```bash
scripts/git/get-issues.sh <gitlab-remote> --state open --limit 50
scripts/git/get-issues.sh <gitlab-remote> --state open --scope authored --limit 50
scripts/git/get-issues.sh <gitlab-remote> --state open --scope assigned --limit 50
scripts/git/glab/get-issues.sh --repo <group/project> --state opened --scope all --limit 50
```

The generic helper resolves named GitLab remotes before delegating to the GitLab helper. Use `--scope authored` or `--scope assigned` when the user asks for their issues; the GitLab helper resolves the current username before filtering. The GitLab helper emits normalized JSON and includes REST fields that are awkward to extract from `glab issue list`, including task completion and blocking issue metadata.

Fallback commands:

- List issues: `glab issue list --repo <group/project> --opened --output json --per-page 50`
- Issue API: `glab api projects/<url-encoded-project-path>/issues`

## Create And Update

Template locations:

- MR templates: `.gitlab/merge_request_templates/*.md`.
- Issue templates: `.gitlab/issue_templates/*.md`.

Inspect templates before composing MR descriptions, issue bodies, or full body replacements. Use the only applicable template automatically; ask the user which template to use when multiple templates apply.

When an installed or repo-local helper is available, prefer it for issue creation after explicit user intent is confirmed:

```bash
scripts/git/create-issue.sh <gitlab-remote> --title "Issue title" --body-file <file>
scripts/git/create-issue.sh <gitlab-remote> --title "Issue title" --body-file <file> --yes
scripts/git/glab/create-issue.sh --repo <group/project> --title "Issue title" --body-file <file> --yes
```

The issue create helper searches likely duplicate open issues before creating. Without `--yes`, it emits JSON describing the target and duplicate candidates without mutating issue state.

When an installed or repo-local helper is available, prefer it for issue updates after explicit user intent is confirmed:

```bash
scripts/git/update-issue.sh <gitlab-remote> <issue-iid> --comment-file <file>
scripts/git/update-issue.sh <gitlab-remote> <issue-iid> --title "New title" --body-file <file>
scripts/git/update-issue.sh <gitlab-remote> <issue-iid> --add-label bug --remove-label triage --add-assignee <username>
scripts/git/update-issue.sh <gitlab-remote> <issue-iid> --milestone "v1.2" --close
scripts/git/update-issue.sh <gitlab-remote> <issue-iid> --comment-file <file> --yes
scripts/git/glab/update-issue.sh --repo <group/project> --issue <iid> --title "New title" --yes
```

Without `--yes`, the issue update helper snapshots `before` and returns `action` JSON without mutating. With `--yes`, it applies the requested mutation and snapshots `after`.

- Create issue: `glab issue create --repo <group/project> --title <title> --description <description> --yes`
- Comment on issue: `glab issue note <iid> --repo <group/project> -m <message>`
- Edit issue: `glab issue update <iid> --repo <group/project>`
- Close issue: `glab issue close <iid> --repo <group/project>`
- Reopen issue: `glab issue reopen <iid> --repo <group/project>`
- Use the GitLab issue API when labels, assignees, milestones, or description updates are not exposed by the local `glab` version.
- Create draft MR: `glab mr create --draft --source-branch <branch> --target-branch <base> --title <title> --description-file <file>`
- Create ready MR: `glab mr create --source-branch <branch> --target-branch <base> --title <title> --description-file <file>`
- Edit MR: `glab mr update <iid>`
- Checkout MR: `glab mr checkout <iid>`

Prefer file-backed descriptions when the repo has a merge request or issue template.

## CI And Pipelines

When an installed or repo-local helper is available, prefer it for CI watch data:

```bash
scripts/git/glab/get-ci.sh --repo <group/project> --target-type branch --target <branch>
scripts/git/glab/get-ci.sh --repo <group/project> --target-type mr --target <iid>
scripts/git/glab/get-ci.sh --repo <group/project> --target-type pipeline --target <pipeline-id>
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

Prefer `scripts/git/get-pr.sh --host gitlab --repo <target-group/project> --branch <source-branch>` for fork-to-upstream MRs. GitLab comments and discussions live on the target project MR, not necessarily on the fork remote that owns the source branch. Installed `glab` versions vary in supported `mr list` and `pipeline list` flags, so use the helper/API path before ad hoc `glab` fallbacks.

Do not resolve discussions, approve, or edit MR text from read-only watcher/table workflows.

## Merge

- Capture `sha` from the verified MR detail immediately before merge.
- Merge: `glab mr merge <iid> --sha <sha>`
- Squash or remove source branch only when requested or repo policy clearly requires it.
- Merge train behavior may require GitLab API or project-specific policy checks.

Confirm merge method and squash/source-branch behavior when policy is unclear.

## Merge Request Notes

GitLab merge requests can have draft state, approvals, discussions, pipelines, merge trains, squash settings, and branch protection. If the user says "GitLab PR", treat that as a merge request.
