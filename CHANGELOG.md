# Changelog

## Unreleased - 2026-05-27

### Added

- Added `$vhs` for repeatable terminal screenshots, GIFs, videos, output guidance, runner selection, deterministic fixture guidance, and GIF optimization with Charmbracelet VHS.
- Added VHS helper scripts.
  - `scripts/vhs/check.sh` checks required VHS rendering tools and optional optimization tools.
  - `scripts/vhs/render.sh` validates or renders one tape or all configured tapes and reports artifact sizes.
  - `scripts/vhs/optimize-gif.sh` optimizes GIFs with `gifsicle` and replaces originals only when smaller.
  - `scripts/vhs/new-demo.sh` creates starter tapes with deterministic defaults.
- Added `make vhs`, `make vhs-check`, `make vhs-validate`, `make vhs-one`, and `make vhs-new` targets for repo-native VHS workflows.
- Added `scripts/git/codex-color-probe.sh` for checking ANSI, Markdown, HTML, plain-label, and JSON color-hint rendering inside Codex.
- Added shared table output guidance in `references/git-workflow/table.md`.
  - Keeps full URLs out of tables and moves raw links into a terminal-friendly `Links:` section.
  - Defines compact table rules for issue, PR, and MR summaries.
  - Documents ANSI color and optional emoji status markers for table cells.
- Added shared helper guidance in `references/git-workflow/helpers.md`.
  - Defines the `scripts/git/` helper location.
  - Documents the contract for read-only JSON helper scripts.
  - Notes that installed skills receive helper/reference shims pointing at shared assets under `~/.agents/gitSkills/`.
- Added GitHub and GitLab issue helper scripts.
  - `scripts/git/gh/get-issues.sh` normalizes lightweight GitHub issue table data.
  - `scripts/git/glab/get-issues.sh` normalizes GitLab issue data, including task completion and blocking metadata.
  - `scripts/git/get-issues.sh` resolves the current checkout, named remote, or GitHub/GitLab URL before delegating to the provider helper.
- Added GitHub PR and GitLab MR helper scripts.
  - `scripts/git/gh/get-prs.sh` normalizes GitHub pull request data, including draft state, review decision, merge state, labels, assignees, branches, and status-check counts.
  - `scripts/git/glab/get-mrs.sh` normalizes GitLab merge request data, including draft state, reviewers, merge status, discussion status, branches, and pipeline data.
  - `scripts/git/get-prs.sh` resolves the current checkout, named remote, GitHub/GitLab URL, or all remotes before delegating to the provider helper and adding table-ready status fields.
- Added GitHub Actions and GitLab pipeline helper scripts.
  - `scripts/git/gh/get-ci.sh` normalizes GitHub PR checks, workflow runs, jobs, failed logs, and run URLs.
  - `scripts/git/glab/get-ci.sh` normalizes GitLab MR pipelines, branch pipelines, jobs, failed logs, and pipeline URLs.
- Added `$git-issue-create` for creating GitHub or GitLab issues after target resolution and duplicate checks.
- Added `$git-issue-details` for inspecting one GitHub or GitLab issue with body, comment, and metadata context.
- Added script-backed issue detail helpers for `$git-issue-details`.
  - `scripts/git/get-issue.sh` resolves the current checkout, named remote, GitHub/GitLab URL, or issue URL before delegating.
  - `scripts/git/gh/get-issue.sh` and `scripts/git/glab/get-issue.sh` normalize one issue's body, metadata, and comments.
- Added script-backed issue creation helpers for `$git-issue-create`.
  - `scripts/git/create-issue.sh` resolves the current checkout, named remote, or GitHub/GitLab URL before delegating.
  - `scripts/git/gh/create-issue.sh` and `scripts/git/glab/create-issue.sh` search likely duplicate open issues and require `--yes` before creating.
- Added a local pre-commit hook configuration that runs `make validate`.
- Added `scripts/git/get-branch-state.sh` for read-only local branch, dirty state, upstream, base, pushed HEAD, and ahead/behind inspection.
- Added `references/git-workflow/pr-description.md` for dense PR/MR description and Markdown table guidance.
- Added `scripts/git/resolve-target.sh` for local-only GitHub/GitLab target resolution shared by generic helpers.
- Added `scripts/git/get-ci.sh` for generic GitHub/GitLab CI target resolution, provider delegation, and all-remotes CI summaries.
- Added `scripts/git/get-pr.sh` plus provider detail helpers for normalized one-PR/MR watcher context.
- Added `$git-branch-sync` for safe read-first branch freshness and synchronization workflows.
- Added `$git-pr-review` for local read-only PR/MR code reviews with findings-first output.
- Added `$git-issue-update` for explicit one-issue comments, edits, metadata changes, close, and reopen workflows.
- Added `scripts/validate-skill-routing.sh` for static skill routing, helper path, reference path, and frontmatter validation.
- Added `references/git-workflow/changelog.md` for lightweight changelog update policy and `$changelog-generator` handoff guidance.
- Added local-only helper JSON smoke tests for `resolve-target.sh` and `get-branch-state.sh`.
- Added `make test-helpers` for running helper smoke tests directly.
- Added GitHub Actions validation for repo-local shell, routing, helper, and ShellCheck checks.
- Added `make ci` for GitHub Actions-safe validation without Codex-local tooling.
- Added a tracked `$git-issue-table` VHS demo GIF and deterministic tape.

### Changed

- Updated install and uninstall scripts to include `$vhs` and shared `scripts/vhs/` helper installation.
- Updated static skill routing validation to include `$vhs` references.
- Updated issue and PR/MR table helpers to emit explicit color-hint metadata while preserving plain status text.
- Updated issue and PR/MR table guidance to prefer Markdown tables with stable status symbols and optional ANSI because fixed-width box tables wrap poorly in Codex.
- Updated `$git-issue-table` to prioritize issue titles and relative update ages instead of labels, owners, work signals, or a generic next-action column.
- Updated GitHub issue collection to use one lightweight `gh issue list` call for the default issue table.
- Updated provider helpers to live under `scripts/git/gh/` and `scripts/git/glab/`.
- Updated `make validate` to syntax-check shell helpers recursively under `scripts/`.
- Updated `make install` to copy shared helper scripts and references once under `~/.agents/gitSkills/` and link each installed skill back to them.
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
- Updated `$git-workflow` to route one-issue body, comment, and metadata inspection to `$git-issue-details`.
- Updated `$git-issue-create` to use the script-backed helper path for normal issue creation.
- Updated shared target-resolution guidance so named remotes such as `origin` or `upstream` are explicit repository targets.
- Removed site-specific remote examples from skill and workflow documentation.
- Added shared target phrasing to `common.md`, including the distinction between bare `all` and `all remotes`.
- Updated `AGENTS.md` to require README and agent matrix relevance checks plus changelog updates before commits.
- Updated `$git-pr-create` to prefer Markdown tables for dense PR/MR description details while keeping simple descriptions concise.
- Updated `$git-pr-create` and `$git-pr-update` to prefer the branch-state helper for initial local branch inspection.
- Updated `$git-pr-create` to load detailed PR/MR description examples only from the focused reference when needed.
- Updated `plan.md` to remove stale implemented backlog entries and compact live next-work planning.
- Added optional `make shellcheck` validation and fixed current demo script ShellCheck warnings.
- Updated generic issue, PR/MR, and issue-creation helpers to use the shared target resolver before provider delegation.
- Updated `scripts/git/get-issues.sh` to support `all remotes` issue collection.
- Updated `$git-ci-watch` and CI references to prefer the generic CI helper.
- Updated `$git-pr-watcher` and review references to prefer the generic PR/MR detail helper.
- Trimmed PR/MR list helper output to default table fields and kept richer relationship data in one-item detail helpers.
- Updated GitHub CI collection to fetch failed logs only when the selected run has failing jobs.
- Updated `$git-workflow`, install scripts, README, and the agent matrix to route branch sync requests.
- Updated `$git-pr`, review references, install scripts, README, and the agent matrix to route local PR/MR review requests.
- Updated issue and mutation references with safe one-issue update guidance.
- Updated `$git-workflow` to ask for an explicit completion endpoint before broad issue implementation requests.
- Updated default `make` behavior to list available targets instead of running `make install`.
- Updated the GitHub Actions validation workflow with manual dispatch and read-only contents permissions.
- Updated `make validate` to run static skill routing validation.
- Updated `make validate` to run local helper JSON smoke tests.
- Updated mutation and commit guidance so changelog updates follow repo-local instructions without adding a separate gitSkills changelog skill.
- Documented policy decisions to avoid a broad `$git-feature` skill, provider-specific alias skills, and plugin packaging until repeated workflow evidence justifies them.
- Refreshed `plan.md` to remove stale backlog detail and point future implementation work to GitHub issues.
- Removed `plan.md`; roadmap and follow-up work now live in GitHub issues, with durable guidance kept in README, references, and skill files.

### Verified

- Ran `make validate`.
- Ran `make shellcheck`.
- Verified GitHub issue collection against `jeeftor/gitSkills`.
- Verified GitLab issue collection against a GitLab-backed test repository.
- Verified shared installed helper/reference symlinks under `~/.agents/skills/`.
