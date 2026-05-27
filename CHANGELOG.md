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
  - `scripts/git/get-issues.sh` remains as a GitHub compatibility wrapper.
- Added GitHub PR and GitLab MR helper scripts.
  - `scripts/git/gh-get-prs.sh` normalizes GitHub pull request data, including draft state, review decision, merge state, labels, assignees, branches, and status-check counts.
  - `scripts/git/glab-get-mrs.sh` normalizes GitLab merge request data, including draft state, reviewers, merge status, discussion status, branches, and pipeline data.
- Added a local pre-commit hook configuration that runs `make validate`.

### Changed

- Updated `make validate` to syntax-check every shell helper under `scripts/*.sh` and `scripts/git/*.sh`.
- Updated `make install` to copy shared helper scripts into every installed skill alongside shared references.
- Updated `README.md` to document shared helper scripts and their install behavior.
- Updated `README.md` to document installing the local hook with `prek install`.
- Updated GitHub and GitLab workflow references to prefer provider-specific helper scripts for issue and PR/MR table data when available.
- Updated `$git-issue-table` and `$git-pr-table` to read shared helper and table references.
- Updated `$git-issue-table`, `$git-pr-table`, and `$git-ci-watch` to support consistent named-remote and `all remotes` target phrasing.
- Updated shared target-resolution guidance so named remotes such as `origin` or `upstream` are explicit repository targets.
- Added shared target phrasing to `common.md`, including the distinction between bare `all` and `all remotes`.

### Verified

- Ran `make validate`.
- Verified GitHub issue collection against `jeeftor/gitSkills`.
- Verified GitLab issue collection against a GitLab-backed test repository.
- Verified installed helper copies under `~/.agents/skills/`.
