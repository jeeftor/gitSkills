# Git Helper Scripts Reference

Use helper scripts for repeated read-only collection and normalization. Keep final prioritization, explanation, and recommendations in Codex.

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
- Helpers should emit structured JSON for Codex to summarize.
- Helpers should normalize repeated platform and target-resolution details, not decide user-facing priorities.
- Helpers should accept explicit `--repo`, `--state`, `--limit`, or similar target flags when practical.
- Helpers should fail clearly when required CLIs such as `gh`, `glab`, or `jq` are missing.
- Helpers should keep plain status values in structured output; use ANSI color only for explicit human-facing output or include separate color hint fields.

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

## Current Helpers

- `scripts/git/gh-get-issues.sh`: collect GitHub issues as normalized JSON, including parent issue, sub-issue, and dependency metadata from the GitHub REST API.
- `scripts/git/glab-get-issues.sh`: collect GitLab issues as normalized JSON, including task completion and blocking issue metadata from the GitLab REST API.
- `scripts/git/get-issues.sh`: resolve the current checkout, named remote, or GitHub/GitLab URL, then collect normalized issue JSON with the provider helper.
- `scripts/git/get-prs.sh`: resolve the current checkout, named remote, GitHub/GitLab URL, or all remotes, then collect normalized PR/MR JSON with table-ready status fields.
- `scripts/git/gh-get-prs.sh`: collect GitHub pull requests as normalized JSON, including draft, review, merge, branch, and status-check fields.
- `scripts/git/glab-get-mrs.sh`: collect GitLab merge requests as normalized JSON, including draft, review, merge, branch, discussion, and pipeline fields.
- `scripts/git/gh-get-ci.sh`: collect GitHub Actions/check status as normalized JSON, including PR checks, workflow runs, jobs, failed logs, and run URLs.
- `scripts/git/glab-get-ci.sh`: collect GitLab pipeline/job status as normalized JSON, including MR pipelines, branch pipelines, jobs, failed logs, and pipeline URLs.
