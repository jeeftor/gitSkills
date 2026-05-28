# Git Helper Scripts Reference

Use helper scripts for repeated target detection, collection, and normalization. Keep final prioritization, explanation, and recommendations in Codex.

## Location

Repo-local helpers live under:

```text
scripts/git/
```

During `make install`, these helpers are copied into each installed skill under:

```text
~/.agents/skills/<skill>/scripts/git/
```

Prefer the installed helper next to the active skill when working outside this repository checkout. Use the repo-local helper when developing this repository.

## Contract

- Helpers should be read-only unless their name and documentation clearly state otherwise.
- Mutating helpers must require an explicit confirmation flag such as `--yes`.
- Helpers should emit structured JSON for Codex to summarize.
- Helpers should normalize repeated platform and target-resolution details, not decide user-facing priorities.
- Helpers should accept explicit `--repo`, `--state`, `--limit`, or similar target flags when practical.
- Helpers should fail clearly when required CLIs such as `gh`, `glab`, or `jq` are missing.
- Helpers should keep plain status values in structured output; use ANSI color only for explicit human-facing output or include separate color hint fields such as `colors` or `table.colors`.

CI helpers should emit this general shape:

```json
{
  "host": "github|gitlab",
  "repo": "owner/name or group/project",
  "target": {"type": "pr|mr|branch|commit|run|pipeline", "value": "..."},
  "status": "Pass|Failing|Pending|Canceled|Skipped|Missing|Unknown",
  "url": "...",
  "commit": "...",
  "branch": "...",
  "jobs": [
    {"name": "...", "status": "...", "url": "...", "required": null, "summary": "..."}
  ],
  "failed_logs": [
    {"job": "...", "summary": "..."}
  ]
}
```

Branch-state helpers should emit this general shape:

```json
{
  "current_branch": "feature/example",
  "is_detached": false,
  "current_head": "...",
  "upstream": {"ref": "origin/feature/example", "head": "...", "exists": true},
  "pushed": {"remote": "origin", "branch": "feature/example", "head": "...", "exists": true},
  "base": {"branch": "master", "remote": "origin", "source": "origin_head", "exists": true},
  "dirty": {
    "is_dirty": true,
    "summary": {"staged": 1, "unstaged": 0, "untracked": 1},
    "staged": [{"status": "M", "path": "file"}],
    "unstaged": [],
    "untracked": [{"status": "??", "path": "new-file"}]
  },
  "ahead_behind": {
    "upstream": {"ahead": 1, "behind": 0},
    "base": {"ahead": 3, "behind": 0},
    "pushed": {"ahead": 1, "behind": 0}
  }
}
```

Use `scripts/git/get-branch-state.sh` at the start of PR/MR create and update workflows to inspect the current branch, default/base branch guess, upstream or pushed commit state, and dirty working-tree summaries. It is a local-only snapshot; still use provider helpers or platform CLIs to detect duplicate PRs/MRs, verify remote review state, and inspect CI.

Target-resolution helpers should emit this general shape:

```json
{
  "host": "github|gitlab|mixed",
  "repo": "owner/name or group/project",
  "source": "explicit|remote|url|branch_upstream|origin|upstream|all_remotes",
  "remote": "origin",
  "url": "https://github.com/owner/repo"
}
```

For `--all-remotes`, `repo` is `null` and `targets` contains one normalized target per distinct GitHub or GitLab repository. Use `scripts/git/resolve-target.sh` inside generic helpers before delegating to provider-specific collectors or mutators. Keep the resolver local-only; it should not call GitHub or GitLab APIs.

## Current Helpers

- `scripts/git/resolve-target.sh`: resolve the current checkout, named remote, GitHub/GitLab URL, explicit repository, or all remotes into normalized target JSON without platform API calls.
- `scripts/git/get-branch-state.sh`: inspect the current branch, upstream, base branch guess, dirty state summaries, ahead/behind counts, current HEAD, and local pushed/upstream HEADs for PR/MR create and update workflows.
- `scripts/git/get-issues.sh`: resolve the current checkout, named remote, or GitHub/GitLab URL, then collect normalized issue JSON with the provider helper.
- `scripts/git/get-issue.sh`: resolve the current checkout, named remote, GitHub/GitLab URL, or issue URL, then collect normalized detail JSON for one issue.
- `scripts/git/get-prs.sh`: resolve the current checkout, named remote, GitHub/GitLab URL, or all remotes, then collect normalized PR/MR JSON with table-ready status and color-hint fields.
- `scripts/git/get-pr.sh`: resolve the current checkout, named remote, GitHub/GitLab URL, PR/MR URL, number, IID, or branch, then collect normalized detail JSON for one PR/MR.
- `scripts/git/get-ci.sh`: resolve the current checkout, named remote, GitHub/GitLab URL, or all remotes, then collect normalized CI JSON with the provider helper.
- `scripts/git/codex-color-probe.sh`: print ANSI, Markdown, HTML, plain-label, and JSON color-hint samples to test what the current Codex surface renders.
- `scripts/git/create-issue.sh`: resolve the current checkout, named remote, or GitHub/GitLab URL, then delegate issue creation to the provider helper.
- `scripts/git/gh/get-issues.sh`: collect GitHub issues as normalized JSON using the lightweight issue list API fields needed for issue tables.
- `scripts/git/gh/get-issue.sh`: collect one GitHub issue as normalized JSON, including body, labels, assignees, milestone, and comments.
- `scripts/git/gh/get-prs.sh`: collect GitHub pull requests as normalized JSON, including draft, review, merge, branch, and status-check fields.
- `scripts/git/gh/get-pr.sh`: collect one GitHub pull request as normalized JSON, including body, comments, reviews, merge state, branches, and status checks.
- `scripts/git/gh/get-ci.sh`: collect GitHub Actions/check status as normalized JSON, including PR checks, workflow runs, jobs, failed logs, and run URLs.
- `scripts/git/gh/create-issue.sh`: create a GitHub issue after duplicate search and explicit `--yes` confirmation.
- `scripts/git/glab/get-issues.sh`: collect GitLab issues as normalized JSON, including task completion and blocking issue metadata from the GitLab REST API.
- `scripts/git/glab/get-issue.sh`: collect one GitLab issue as normalized JSON, including description, labels, assignees, milestone, notes, and task metadata.
- `scripts/git/glab/get-mrs.sh`: collect GitLab merge requests as normalized JSON, including draft, review, merge, branch, discussion, and pipeline fields.
- `scripts/git/glab/get-mr.sh`: collect one GitLab merge request as normalized JSON, including description, discussions, approvals, merge state, branches, and pipeline fields.
- `scripts/git/glab/get-ci.sh`: collect GitLab pipeline/job status as normalized JSON, including MR pipelines, branch pipelines, jobs, failed logs, and pipeline URLs.
- `scripts/git/glab/create-issue.sh`: create a GitLab issue after duplicate search and explicit `--yes` confirmation.
