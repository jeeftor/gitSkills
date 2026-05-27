# Git CI Reference

Use this reference for GitHub Actions/checks and GitLab pipelines/jobs.

## Target Resolution

Resolve the CI target in this order:

1. Explicit run, pipeline, job, URL, PR, MR, or commit SHA from the user.
2. The PR or MR associated with the current branch.
3. The latest pushed commit on the current branch.
4. The current local `HEAD` commit, clearly labeled as local if it has not been pushed.

If the target could refer to multiple runs or pipelines, prefer the newest run for the same commit and ask before taking mutating action.

## Normalized Status

- `Pass`: required checks or jobs completed successfully.
- `Failing`: one or more required or relevant checks failed.
- `Pending`: checks or jobs are queued, running, or waiting.
- `Canceled`: the latest relevant run or pipeline was canceled.
- `Skipped`: checks were intentionally skipped.
- `Missing`: no CI data was found for the target.
- `Unknown`: CI exists but the status cannot be determined from available tools.

Treat missing or partial data as unknown, not successful.

## GitHub CI

When an installed or repo-local helper is available, prefer it for CI watch data:

```bash
scripts/git/gh/get-ci.sh --repo <owner/repo> --target-type branch --target <branch>
scripts/git/gh/get-ci.sh --repo <owner/repo> --target-type pr --target <number>
scripts/git/gh/get-ci.sh --repo <owner/repo> --target-type run --target <run-id>
```

The helper emits normalized JSON with `Pass`, `Failing`, `Pending`, `Canceled`, `Skipped`, `Missing`, or `Unknown`, plus job rows, failed log summaries, run URL, commit, and branch when available.

Useful commands:

- PR checks: `gh pr checks <number> --repo <owner/repo>`
- PR status fields: `gh pr view <number> --repo <owner/repo> --json statusCheckRollup,headRefOid,headRefName`
- Workflow runs for a branch: `gh run list --repo <owner/repo> --branch <branch> --limit 20`
- Workflow run details: `gh run view <run-id> --repo <owner/repo> --log-failed`
- Workflow run jobs: `gh run view <run-id> --repo <owner/repo> --json status,conclusion,jobs,headSha,url`

Use GraphQL or `gh api` when required-check metadata, check suites, or merge queue details are missing from the CLI output.

## GitLab CI

When an installed or repo-local helper is available, prefer it for CI watch data:

```bash
scripts/git/glab/get-ci.sh --repo <group/project> --target-type branch --target <branch>
scripts/git/glab/get-ci.sh --repo <group/project> --target-type mr --target <iid>
scripts/git/glab/get-ci.sh --repo <group/project> --target-type pipeline --target <pipeline-id>
```

The helper emits normalized JSON with `Pass`, `Failing`, `Pending`, `Canceled`, `Skipped`, `Missing`, or `Unknown`, plus job rows, failed log summaries, pipeline URL, commit, and branch when available.

Useful commands:

- MR pipeline summary: `glab mr view <iid>`
- Pipelines for a branch: `glab pipeline list --branch <branch>`
- Pipeline details: `glab pipeline view <pipeline-id>`
- Job details and logs: `glab ci view` or GitLab API calls when `glab` lacks the needed fields.

Use the GitLab API when job logs, downstream pipelines, approvals tied to pipelines, or merge train pipeline state are missing from `glab`.

## Safety

- Watching CI is read-only by default.
- Do not rerun, cancel, approve, merge, rebase, push, or retry jobs unless the user explicitly asks.
- Do not call a failure flaky without evidence such as a known intermittent job, a successful rerun on the same commit, or project documentation.
