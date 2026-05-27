# gitSkills Plan

Repository: https://github.com/jeeftor/gitSkills

## Goal

Create a global Codex skill bundle for common GitHub and GitLab workflows, while keeping Home Assistant-specific skills repo-local to Home Assistant Core.

## Current Direction

- `gitSkills` is the global bundle for reusable Git, GitHub, and GitLab workflows.
- `agentSkills` remains the Home Assistant-specific bundle.
- Generic Git skills should install globally under `~/.agents/skills`.
- HA skills should eventually install repo-local under `~/devel/ha/core/.agents/skills`.
- This repository uses `master` as its default branch and first release branch.

Official Codex docs checked on 2026-05-27 identify skill discovery paths as:

- Repo-local skills: `.agents/skills` from the current working directory up to the repository root.
- User-global skills: `$HOME/.agents/skills`.
- Admin skills: `/etc/codex/skills`.
- System skills: bundled with Codex.

Each skill is a directory with a required `SKILL.md` file.

Use both installer approaches for different jobs:

- `make install` / `make uninstall` / `make validate` are for this repository's local development loop and should copy this checkout's skills to `~/.agents/skills`.
- `$skill-installer` is for installing curated skills or downloading skills from GitHub repo paths for local setup and experimentation, but the bundled installer currently writes to `$CODEX_HOME/skills`, defaulting to `~/.codex/skills`.
- Plugins are the preferred distribution unit if `gitSkills` should become a reusable package for other developers.
- Use `$HOME/.agents/skills`, not `$HOME/.agent/skills`.

## Proposed Skill Set

Current initial global skills:

- `$git-issue-table` - summarize GitHub or GitLab issues.
- `$git-pr` - route PR/MR work to the right specialist skill.
- `$git-pr-table` - summarize GitHub pull requests or GitLab merge requests.
- `$git-pr-watcher` - inspect one PR or MR.
- `$git-ci-watch` - watch CI for a branch, commit, latest push, PR, MR, run, or pipeline.
- `$git-pr-create` - create a PR or MR.
- `$git-pr-update` - update an existing PR or MR branch.
- `$git-pr-merge` - merge an approved PR or MR.

Use `git-pr-*` even for GitLab because the user often says "PR"; skill bodies should map GitLab PR wording to merge requests.

## Completed So Far

- Connected the local repo to `https://github.com/jeeftor/gitSkills` as `origin`.
- Added `$git-pr` as a generic PR/MR router, modeled after the HA `$ha-pr` coordinator pattern.
- Added `$git-ci-watch` for read-only CI monitoring across latest pushes, branches, commits, PRs, MRs, GitHub Actions runs, and GitLab pipelines.
- Made `$git-pr-watcher` read-only and routed CI-only requests to `$git-ci-watch`.
- Added `references/git-workflow/ci.md`.
- Updated `make install` so shared references are copied into each installed skill under `~/.agents/skills/<skill>/references/git-workflow/`.
- Added optimized README artwork at `assets/gitSkills.webp`.
- Documented `gh` and `glab` CLI requirements in README.
- Expanded shared host/target detection rules for repositories that have both GitHub and GitLab signals.
- Verified `make validate` passes for the current eight skills.

## Skill Authoring Workflow

Use `$skill-creator` as the authoring guide for these skills:

- For brand-new skills, run `skill-creator/scripts/init_skill.py` into this repository's `skills/` directory, not directly into a global install directory.
- For the already scaffolded `git-*` skills, do not regenerate folders unless validation shows the scaffold is wrong.
- Keep each `SKILL.md` concise, with trigger-focused `name` and `description` frontmatter.
- Put longer host-specific workflow details in `references/git-workflow/` and link them from the relevant skill body.
- Run `skill-creator/scripts/quick_validate.py` for every skill before install or distribution.
- Decide whether to add `agents/openai.yaml` metadata after the skill wording stabilizes.

## Shared References

Use shared references to keep skill bodies short:

- `references/git-workflow/common.md`
  - host detection
  - common status terms
  - branch safety
  - mutation safety
- `references/git-workflow/github.md`
  - `gh` commands
  - GitHub checks/reviews/mergeability
  - GraphQL fallback notes
- `references/git-workflow/gitlab.md`
  - `glab` commands
  - GitLab pipelines/approvals/discussions/merge trains
  - GitLab API fallback notes
- `references/git-workflow/ci.md`
  - CI target resolution
  - normalized CI statuses
  - GitHub Actions and GitLab pipeline commands
  - read-only CI safety rules

## Scope Boundaries

Keep `gitSkills` focused on reusable Git, GitHub, and GitLab workflow mechanics:

- host and repository detection
- branch and dirty-state safety
- issue, PR, MR, CI, and merge lifecycle
- changelog/release-note workflow only when tied to repository release or PR preparation

Do not turn the first release into a general coding bundle. Generic feature implementation is usually project-specific and should be driven by repo-local instructions, language/framework skills, or domain skills such as HA's `$ha-feature`.

If a future implementation skill is added, keep it narrow: it should coordinate branch setup, smallest verifiable goal, local verification, changelog/docs checks, and PR handoff. It should not replace domain-specific implementation skills.

## Detection Strategy

Do not detect host from branch names. Branch names describe workflow intent, not hosting platform.

Detection order:

1. User-provided URL or explicit platform.
2. `git remote get-url origin`.
3. `git remote get-url upstream`.
4. Repo markers such as `.github/` or `.gitlab-ci.yml`.
5. Authenticated CLI availability: `gh auth status` or `glab auth status`.
6. Ask when ambiguous.

## Install Behavior

For `gitSkills`:

- Install global skills to `~/.agents/skills`.
- Do not install into `~/.codex/skills`.
- Keep shared references once in the source tree under `references/git-workflow/`, and have `make install` copy them into each installed skill under `~/.agents/skills/<skill>/references/git-workflow/` so installed skills are self-contained.
- Provide `make install`, `make uninstall`, and `make validate`.
- Keep the Makefile because it supports local checkout development, validation, uninstall, and repeatable updates.
- Do not recommend `$skill-installer` as the primary install path for this bundle until the installer destination is confirmed to align with current Codex skill discovery docs, or until install instructions explicitly pass `--dest "$HOME/.agents/skills"`.
- Document `$skill-installer` only as an optional GitHub-download path, with plugins preferred for longer-term distribution.
- Restart Codex after installing or uninstalling.

For HA `agentSkills`:

- Install HA skills repo-local to `~/devel/ha/core/.agents/skills`.
- Remove legacy global HA skills from old locations only as part of a separate, explicit HA migration.
- Keep shared HA references and config under `~/.codex/ha-assistant` for now unless the HA skills are refactored to bundle references differently.

## HA Relationship

Do not make HA skills hard-depend on `gitSkills` initially.

Preferred staged approach:

1. Build and validate `gitSkills` independently.
2. Keep HA skills domain-specific and repo-local.
3. Later refactor HA PR skills to mirror the shared Git lifecycle language.
4. Only add explicit `$git-*` handoffs from `$ha-*` skills if install order and skill discovery are reliable.

HA-specific behavior should remain in HA skills:

- HA Core base branch is `dev`.
- Preserve the HA PR template.
- Run HA integration-scoped verification.
- Check HA Core Copilot instructions before PR create/update.
- Route docs, quality scale, backing-library, and integration follow-up.

`$ha-feature` is not a direct template for an immediate generic `$git-feature`. It is valuable as a workflow shape, but its actual behavior is HA-specific: integration domain inference, backing-library ownership, HA Core patterns, tests, docs, and HA follow-up skills. A generic feature skill should wait until the Git workflow boundary is clear.

## Scaffold Already Started

The following files were scaffolded locally:

- `AGENTS.md`
- `README.md`
- `agent-matrix.md`
- `Makefile`
- `scripts/install.sh`
- `scripts/uninstall.sh`
- `references/git-workflow/common.md`
- `references/git-workflow/github.md`
- `references/git-workflow/gitlab.md`
- `skills/git-issue-table/SKILL.md`
- `skills/git-pr/SKILL.md`
- `skills/git-pr-table/SKILL.md`
- `skills/git-pr-watcher/SKILL.md`
- `skills/git-ci-watch/SKILL.md`
- `skills/git-pr-create/SKILL.md`
- `skills/git-pr-update/SKILL.md`
- `skills/git-pr-merge/SKILL.md`

## Immediate Next Steps

1. Expand `references/git-workflow/common.md` with shared target resolution, default branch detection, dirty-state policy, PR/MR lookup rules, and mutation safety.
2. Expand `references/git-workflow/github.md` and `references/git-workflow/gitlab.md` with concrete create/update/merge/CI/review commands and API fallbacks.
3. Update README install docs to distinguish local Makefile installs from `$skill-installer` and future plugin distribution.
4. Review scaffolded skill wording for trigger clarity and excessive overlap.
5. Use `$skill-creator` guidance to revise the existing `SKILL.md` files without regenerating them.
6. Run:

   ```bash
   sh -n scripts/install.sh
   sh -n scripts/uninstall.sh
   for skill in skills/*; do ~/.codex/codex-python ~/.codex/skills/.system/skill-creator/scripts/quick_validate.py "$skill"; done
   ```

7. Decide whether any additional skill metadata is needed after the workflows settle.
8. Install locally with `make install` and restart Codex.
9. After publishing to GitHub, test installation through `$skill-installer --dest "$HOME/.agents/skills"` using the repository path, or defer GitHub-path installation in favor of plugin packaging.

## Future Work

Candidate skills to consider after the initial PR/MR lifecycle is solid:

- `$git-init`: initialize or connect a local repository, add or verify remotes, choose the preferred default branch, make the first commit, and push the first branch. Defer until the PR/MR lifecycle is stable.
- `$git-pr-address-comments`: inspect review comments or unresolved threads and make requested code/doc/test changes, then hand off to `$git-pr-update`.
- `$git-branch-sync`: update a branch from its base branch, handle behind/conflict states, and manage rebase/merge/force-with-lease safety.
- `$git-pr-review`: review someone else's PR/MR, check out safely, run targeted verification, and prepare review findings or comments.
- `$git-changelog`: update `CHANGELOG.md`, release notes, or similar project changelog files when preparing a PR or release. This should respect existing changelog format and project release tooling instead of inventing a format.
- `$git-release-notes`: summarize merged PRs/MRs or commits into release notes. This may overlap with `$git-changelog`; do not add both unless the workflows are clearly different.
- `$git-issue-create` and `$git-issue-update`: create or edit issues, labels, milestones, and assignments. Keep `$git-issue-table` read-only.
- `$git-feature`: possible broad workflow coordinator for starting or finishing a feature branch, but defer until its boundary is clear. It should coordinate Git workflow, verification, changelog/docs checks, and PR handoff, not replace project-specific implementation guidance.

Open design questions for future work:

- Should changelog support live in this repo, use the existing `$changelog-generator` skill, or only be referenced as a handoff?
- Should `$git-feature` exist, or should generic feature work remain outside this Git workflow bundle?
- Should `$git-init` exist for first-time repo setup, or should initialization remain ordinary Codex behavior plus repo-local instructions?
- Should there be a top-level `$git-workflow` router above `$git-pr`, `$git-ci-watch`, issue skills, changelog skills, and future release skills?

## Open Questions

- Should `gitSkills` later become a Codex plugin, or is GitHub-path installation through `$skill-installer` enough for personal use?
- Should any alias skills exist, such as `$gl-mr-table`, or should `git-pr-*` stay the only interface?
- Should mutating skills default to draft PR/MR creation, or leave draft behavior to repo-specific guidance?
- Should issue workflows include create/update skills in the first release, or only the read-only issue table?
- Should changelog and release-note workflows be first-class skills or handoffs to `$changelog-generator`?
- Is a generic `$git-feature` valuable enough, or too broad compared with repo-local/domain-specific skills?
