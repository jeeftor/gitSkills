# gitSkills Plan

Repository: https://github.com/jeeftor/gitSkills

## Current State

`gitSkills` is a personal/global Codex skill bundle for reusable Git, GitHub, and GitLab workflows. It is installed globally under:

```text
~/.agents/skills/
```

The repo uses `master` as its default branch.

The first usable skill set is written, installed, validated, committed, and pushed:

- `$git-issue-table` - summarize GitHub or GitLab issues.
- `$git-pr` - route PR/MR work to the right specialist skill.
- `$git-pr-table` - summarize GitHub pull requests or GitLab merge requests.
- `$git-pr-watcher` - inspect one PR or MR and produce a read-only action plan.
- `$git-ci-watch` - watch CI for a branch, commit, latest push, PR, MR, run, or pipeline.
- `$git-pr-create` - create a PR or MR.
- `$git-pr-update` - update an existing PR or MR branch.
- `$git-pr-merge` - merge an approved PR or MR.

## Settled Decisions

- Use `~/.agents/skills`, not `~/.agent/skills` or `~/.codex/skills`, for this repo's Makefile install path.
- Keep references DRY in Git under `references/git-workflow/`.
- During `make install`, copy shared references into each installed skill so every skill is self-contained under `~/.agents/skills/<skill>/`.
- Token efficiency depends on what a skill reads, not on how many reference copies exist on disk.
- Use `gh` for GitHub workflows and `glab` for GitLab workflows; both are required when using the matching platform.
- Keep `rg`, `fd`, `gum`, and personal display preferences in global or repo-local `AGENTS.md`, not repeated in every skill.
- Keep `$git-pr-watcher` read-only. Use `$git-ci-watch` for CI-only work and `$git-pr-update` for branch/code updates.
- For repositories with both GitHub and GitLab signals, explicit user intent wins. Branch upstream beats generic remotes. Ask before mutating when the platform is ambiguous.
- Do not make HA skills depend on `gitSkills` yet. HA-specific workflows stay in `agentSkills`.

## Install And Update

Local development install:

```bash
make install
```

Validation:

```bash
make validate
```

After changing references or skill bodies:

```bash
git pull
make install
```

Restart Codex after installing or updating skills.

`$skill-installer` can install individual skills from GitHub, but it currently defaults to `$CODEX_HOME/skills` and does not copy this repo's top-level shared references. For now, prefer the Makefile from a checkout.

## Next Phase

Use the skills on real work before adding many new ones.

During normal use, watch for:

- Trigger problems: the wrong skill fires, or a request is ambiguous.
- Missing target resolution: current branch, upstream, PR/MR number, URL, remote, or mixed GitHub/GitLab case.
- CI gaps: checks, runs, pipelines, jobs, logs, retry/rerun wording.
- Mutation safety gaps: commit, push, rebase, force-with-lease, merge, branch delete, default branch protection.
- Output quality: tables too verbose, missing blockers, poor next-action recommendations.
- Reference loading: skills reading too much context or missing the right host-specific reference.

Immediate improvement areas:

1. Expand `references/git-workflow/common.md` with default branch detection, dirty-state policy, PR/MR lookup rules, and mutation safety.
2. Expand `references/git-workflow/github.md` with concrete `gh` commands for create, update, review, merge, CI, and API fallbacks.
3. Expand `references/git-workflow/gitlab.md` with concrete `glab` commands for create, update, approvals, discussions, merge, pipeline inspection, and API fallbacks.
4. Use the installed skills against this repo and at least one GitLab-backed repo, then patch based on observed misses.

## Future Work

Candidate skills after the initial PR/MR lifecycle proves useful:

- `$git-init`: initialize or connect a local repo, add or verify remotes, choose the preferred default branch, make the first commit, and push the first branch.
- `$git-pr-address-comments`: inspect review comments or unresolved threads and make requested code/doc/test changes, then hand off to `$git-pr-update`.
- `$git-branch-sync`: update a branch from its base branch, handle behind/conflict states, and manage rebase/merge/force-with-lease safety.
- `$git-pr-review`: review someone else's PR/MR, check out safely, run targeted verification, and prepare review findings or comments.
- `$git-changelog`: update `CHANGELOG.md`, release notes, or similar project changelog files when preparing a PR or release.
- `$git-release-notes`: summarize merged PRs/MRs or commits into release notes. Do not add this separately from `$git-changelog` unless the workflows are clearly different.
- `$git-issue-create` and `$git-issue-update`: create or edit issues, labels, milestones, and assignments. Keep `$git-issue-table` read-only.
- `$git-feature`: possible broad coordinator for feature branch setup, smallest verifiable goal, verification, changelog/docs checks, and PR handoff. Defer because generic feature implementation can become too broad.
- `$git-workflow`: possible top-level router above PR, issue, CI, changelog, release, and future initialization workflows.

## Open Questions

- Should changelog support live here, use `$changelog-generator`, or only be referenced as a handoff?
- Should `$git-feature` exist, or should feature work stay repo-local/domain-specific?
- Should `$git-init` exist for first-time repo setup, or should initialization remain ordinary Codex behavior plus repo-local instructions?
- Should aliases such as `$gl-mr-table` exist, or should `git-pr-*` remain the single interface for both PRs and MRs?
- Should this eventually become a Codex plugin, or is repo checkout plus `make install` enough for personal use?
