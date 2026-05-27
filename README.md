# Codex Git Skills

<p align="center">
  <img src="assets/gitSkills.webp" alt="gitSkills mascot" width="480">
</p>

Codex Git Skills is a global skill bundle for GitHub and GitLab issue, pull request, and merge request workflows.

It installs plain skill names:

- ⭐ `$git-workflow` - choose a Git, GitHub, or GitLab workflow
- ⭐ `$git-pr` - route GitHub pull request or GitLab merge request work
- ⭐ `$git-ci-watch` - watch CI for a branch, commit, latest push, pull request, merge request, run, or pipeline
- ⭐ `$git-issue-table` - summarize open GitHub issues or GitLab issues
- `$git-pr-table` - summarize open GitHub pull requests or GitLab merge requests
- `$git-pr-watcher` - inspect one pull request or merge request
- `$git-pr-address-comments` - address review comments on an existing pull request or merge request
- `$git-pr-create` - create a GitHub pull request or GitLab merge request
- `$git-pr-update` - commit and push updates to an existing pull request or merge request
- `$git-pr-merge` - merge an approved pull request or merge request

See [agent-matrix.md](agent-matrix.md) for the skill routing hierarchy.

## Requirements

These skills are built around the platform CLIs:

- GitHub workflows require `gh` with authentication configured.
- GitLab workflows require `glab` with authentication configured.
- Helper scripts require `jq`.
- Local hook installation uses `prek`.

The skills prefer `gh` and `glab` for normal operations and use platform APIs only when the CLI output is missing required details.

## Helper Scripts

Read-only helper scripts live under `scripts/git/` and emit normalized JSON for table and CI workflows:

- `gh-get-issues.sh` - collect GitHub issues.
- `glab-get-issues.sh` - collect GitLab issues.
- `gh-get-prs.sh` - collect GitHub pull requests.
- `glab-get-mrs.sh` - collect GitLab merge requests.
- `gh-get-ci.sh` - collect GitHub Actions/check status.
- `glab-get-ci.sh` - collect GitLab pipeline/job status.
- `get-issues.sh` - compatibility wrapper for GitHub issue collection.

Examples:

```bash
scripts/git/gh-get-issues.sh --repo jeeftor/gitSkills --state open --limit 50
scripts/git/glab-get-issues.sh --repo jeef/gitskills --state opened --limit 50
scripts/git/gh-get-prs.sh --repo jeeftor/gitSkills --state open --scope all --limit 50
scripts/git/glab-get-mrs.sh --repo jeef/gitskills --state opened --scope all --limit 50
scripts/git/gh-get-ci.sh --repo jeeftor/gitSkills --target-type branch --target master
scripts/git/glab-get-ci.sh --repo group/project --target-type branch --target main
```

## Install

From this checkout:

```bash
make install
```

The installer copies skills to:

```text
~/.agents/skills/
```

Shared workflow references are kept once in this repository under `references/git-workflow/`.
Shared helper scripts are kept under `scripts/git/`.
During install, those references and helpers are copied into each installed skill so every skill is self-contained under `~/.agents/skills/<skill>/`.

Restart Codex after installation.

## Development

This repository uses `master` as its default branch.

Validate before pushing:

```bash
make validate
```

Install the local commit hook with:

```bash
prek install
```

The hook runs `make validate` before each commit.

The skills use shared references under `references/git-workflow/`, helper scripts under `scripts/git/`, and load GitHub or GitLab details only after detecting the repository host.
