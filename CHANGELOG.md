# Changelog

## Unreleased - 2026-05-27

### Added

- Added shared table output guidance in `references/git-workflow/table.md`.
  - Keeps full URLs out of tables and moves raw links into a terminal-friendly `Links:` section.
  - Defines compact table rules for issue, PR, and MR summaries.
  - Documents ANSI color and optional emoji status markers for table cells.
- Added shared helper guidance in `references/git-workflow/helpers.md`.
  - Defines the `scripts/git/` helper location.
  - Documents the contract for read-only JSON helper scripts.
  - Notes that installed skills receive helper copies under `~/.agents/skills/<skill>/scripts/git/`.
- Added GitHub and GitLab issue helper scripts.
  - `scripts/git/gh-get-issues.sh` normalizes GitHub issue data, including parent issue, sub-issue, and dependency metadata.
  - `scripts/git/glab-get-issues.sh` normalizes GitLab issue data, including task completion and blocking metadata.
  - `scripts/git/get-issues.sh` resolves the current checkout, named remote, or GitHub/GitLab URL before delegating to the provider helper.
- Added GitHub PR and GitLab MR helper scripts.
  - `scripts/git/gh-get-prs.sh` normalizes GitHub pull request data, including draft state, review decision, merge state, labels, assignees, branches, and status-check counts.
  - `scripts/git/glab-get-mrs.sh` normalizes GitLab merge request data, including draft state, reviewers, merge status, discussion status, branches, and pipeline data.
  - `scripts/git/get-prs.sh` resolves the current checkout, named remote, GitHub/GitLab URL, or all remotes before delegating to the provider helper and adding table-ready status fields.
- Added GitHub Actions and GitLab pipeline helper scripts.
  - `scripts/git/gh-get-ci.sh` normalizes GitHub PR checks, workflow runs, jobs, failed logs, and run URLs.
  - `scripts/git/glab-get-ci.sh` normalizes GitLab MR pipelines, branch pipelines, jobs, failed logs, and pipeline URLs.
- Added `$git-issue-create` for creating GitHub or GitLab issues after target resolution and duplicate checks.
- Added a local pre-commit hook configuration that runs `make validate`.

### Changed

- Updated `make validate` to syntax-check every shell helper under `scripts/*.sh` and `scripts/git/*.sh`.
- Updated `make install` to copy shared helper scripts into every installed skill alongside shared references.
- Updated `README.md` to document shared helper scripts and their install behavior.
- Updated `README.md` to document helper script prerequisites and usage examples.
- Updated `README.md` to document installing the local hook with `prek install`.
- Updated GitHub and GitLab workflow references to prefer provider-specific helper scripts for issue and PR/MR table data when available.
- Updated `$git-issue-table` to use the generic issue helper for normal target resolution before falling back to manual target inspection.
- Updated `$git-pr-table` to use the generic PR/MR helper for normal target resolution and table-ready status fields before falling back to manual target inspection.
- Updated `AGENTS.md` to prefer script-backed common paths when workflows require repeated target-resolution commands.
- Updated CI workflow references to prefer provider-specific helper scripts for CI watch data when available.
- Updated `$git-issue-table` and `$git-pr-table` to read shared helper and table references.
- Updated `$git-issue-table`, `$git-pr-table`, and `$git-ci-watch` to support consistent named-remote and `all remotes` target phrasing.
- Updated `$git-workflow` to route explicit create, open, and file issue requests to `$git-issue-create`.
- Updated shared target-resolution guidance so named remotes such as `origin` or `upstream` are explicit repository targets.
- Removed site-specific remote examples from skill and workflow documentation.
- Added shared target phrasing to `common.md`, including the distinction between bare `all` and `all remotes`.
- Updated `AGENTS.md` to require README and agent matrix relevance checks plus changelog updates before commits.
- Updated `$git-pr-create` to prefer Markdown tables for dense PR/MR description details while keeping simple descriptions concise.

### Verified

- Ran `make validate`.
- Verified GitHub issue collection against `jeeftor/gitSkills`.
- Verified GitLab issue collection against a GitLab-backed test repository.
- Verified installed helper copies under `~/.agents/skills/`.
