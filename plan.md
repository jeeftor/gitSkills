# gitSkills Plan

Repository: https://github.com/jeeftor/gitSkills

## Current State

`gitSkills` is a personal/global Codex skill bundle for reusable Git, GitHub, and GitLab workflows. It is installed globally under:

```text
~/.agents/skills/
```

The repo uses `master` as its default branch.

The first usable skill set is written, installed, validated, committed, and pushed. Starred skills are the primary entry points:

- ⭐ `$git-workflow` - top-level router for choosing a Git, GitHub, or GitLab workflow.
- ⭐ `$git-pr` - route PR/MR work to the right specialist skill.
- ⭐ `$git-ci-watch` - watch CI for a branch, commit, latest push, PR, MR, run, or pipeline.
- ⭐ `$git-issue-table` - summarize GitHub or GitLab issues.
- `$git-pr-table` - summarize GitHub pull requests or GitLab merge requests.
- `$git-pr-watcher` - inspect one PR or MR and produce a read-only action plan.
- `$git-pr-address-comments` - address clear review comments with local changes before handoff to update.
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
- Do not use `allowed-tools` frontmatter for now. The Agent Skills spec marks it experimental and client support varies, so it is not a reliable way to guarantee tool access in Codex.
- Mark only primary entry-point skills with ⭐ so Codex skill lists are easier to scan without making every skill look equally important. `$git-workflow` is the broadest start-here skill.
- Keep frontmatter descriptions short because Codex includes installed skill metadata in its initial context.
- Keep `$git-pr-watcher` read-only. Use `$git-ci-watch` for CI-only work and `$git-pr-update` for branch/code updates.
- Respect each target repo's `.gitignore`; do not stage ignored local artifacts unless the user explicitly asks.
- Never blindly run `git add -A`, `git add .`, `git commit -a`, or broad equivalent staging commands. Prefer path-specific staging after reviewing the file list.
- For repositories with both GitHub and GitLab signals, explicit user intent wins. Branch upstream beats generic remotes. Ask before mutating when the platform is ambiguous.
- Use subagents for read-only investigation only when explicitly requested or clearly useful. Keep mutations serialized in the main agent.
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

Keep this plan short. When a command or helper is implemented, move the useful decision into `README.md`, `agent-matrix.md`, `references/git-workflow/`, or the relevant `SKILL.md`, then remove or compact the row here.

## Next Command Backlog

Implement only one or two at a time. Favor commands that reuse the existing GitHub/GitLab target-resolution and table-helper patterns.

| Command | Priority | Scope | Why Next | Keep Simple Boundary |
| --- | --- | --- | --- | --- |
| `$git-branch-sync` | High | Sync current branch with base branch. | Common daily workflow and safety-sensitive enough to deserve a skill. | Detect base/upstream, report ahead/behind, recommend merge or rebase; mutate only when asked. |
| `$git-pr-review` | High | Review someone else's PR/MR. | Natural companion to `$git-pr-watcher`; covers checkout, diff, tests, and review findings. | Read-only by default; no submitted review unless explicitly asked. |
| `$git-changelog` | Medium | Update `CHANGELOG.md` for a change. | This repo now requires changelog updates before commits. | Patch existing changelog style only; do not invent release tooling. |
| `$git-issue-create` | Medium | Create GitHub/GitLab issues from a clear request. | Completes the issue workflow without mixing mutation into `$git-issue-table`. | Title/body/labels only; ask before milestones, assignments, or cross-repo creation. |
| `$git-issue-update` | Medium | Edit or close one issue. | Useful after issue triage finds the next action. | Require an explicit issue target; do not bulk edit. |
| `$git-release-notes` | Low | Summarize merged PRs/MRs or commits. | Useful later, but overlaps `$git-changelog`. | Keep separate only if release summaries prove different from changelog maintenance. |
| `$git-init` | Low | Initialize or connect a repo and first push. | Good demo/VHS candidate but less urgent for daily work. | Local repo, remotes, default branch, first commit; avoid project scaffolding. |
| `$git-prek-setup` | Low | Add a conservative `prek` validate hook. | Helpful for repos that already have a clear validation command. | Configure existing checks only; do not add new linters by default. |

## Next Helper Backlog

These helpers should come before broad new skill work when they remove repeated provider-specific CLI plumbing.

| Helper | Priority | First Consumer | Purpose | Keep Simple Boundary |
| --- | --- | --- | --- | --- |
| `scripts/git/resolve-target.sh` | Medium | Table and CI helpers | Normalize remotes, URLs, hosts, repo slugs, and `all remotes`. | Output target JSON only; do not call platform APIs. |
| `scripts/git/get-branch-state.sh` | Medium | `$git-branch-sync` | Emit branch, upstream, base guess, ahead/behind, dirty state, and pushed HEAD. | Local git only; no mutation. |
| `scripts/git/gh-get-pr.sh` and `scripts/git/glab-get-mr.sh` | Medium | `$git-pr-watcher` | Collect richer single PR/MR detail than list helpers. | Read-only detail collection; no review or merge actions. |

## DRY And Script Opportunities

Add scripts only when repeated commands become noisy, fragile, or easy to get subtly wrong.

| Opportunity | Candidate Helper | Useful For | Notes |
| --- | --- | --- | --- |
| Resolve remotes and hosts once. | `scripts/git/resolve-target.sh` | `$git-issue-table`, `$git-pr-table`, `$git-ci-watch`, future mutation skills. | Normalize `origin`, `upstream`, URLs, and `all remotes` before provider-specific commands. |
| Normalize current branch state. | `scripts/git/get-branch-state.sh` | `$git-branch-sync`, `$git-pr-update`, `$git-pr-create`. | Emit branch, upstream, base guess, ahead/behind, dirty state, and pushed HEAD. |
| Collect one PR/MR deeply. | `scripts/git/gh-get-pr.sh` and `scripts/git/glab-get-mr.sh` | `$git-pr-watcher`, `$git-pr-review`, `$git-pr-merge`. | Existing table helpers are list-oriented; watcher flows need richer single-item data. |
| Share shell argument checks. | `scripts/git/lib.sh` | All helper scripts. | Only add when helper count grows; current duplication is tolerable. |
| Exercise routing examples. | `scripts/validate-skill-routing.sh` | `make validate`, future trigger tests. | Start as a lightweight metadata/reference check, not a model-eval harness. |

## Future Policy Notes

- Extend `$git-workflow` only when a new command is actually implemented.
- Keep `$git-issue-table`, `$git-pr-table`, and `$git-pr-watcher` read-only.
- Keep local git state, staging, commit, push, rebase, and merge safety grounded in local `git` plus explicit user intent.
- If GitHub or GitLab MCP servers become available, prefer them only for structured read operations where they are clearly better than CLI output.

## Open Questions

- Should changelog support live here, use `$changelog-generator`, or only be referenced as a handoff?
- Should `$git-feature` exist, or should feature work stay repo-local/domain-specific?
- Should `$git-init` exist for first-time repo setup, or should initialization remain ordinary Codex behavior plus repo-local instructions?
- Should `$git-prek-setup` install only hook config, or also add formatter/linter dependencies when a language ecosystem already has an established tool?
- If GitHub/GitLab MCP servers become available, should read-only table/watcher skills prefer MCP first and use `gh`/`glab` as fallback?
- Should aliases such as `$gl-mr-table` exist, or should `git-pr-*` remain the single interface for both PRs and MRs?
- Should this eventually become a Codex plugin, or is repo checkout plus `make install` enough for personal use?
