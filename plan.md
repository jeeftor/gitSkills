# gitSkills Plan

Repository: https://github.com/jeeftor/gitSkills

## Current State

`gitSkills` is a personal/global Codex skill bundle for reusable Git, GitHub, and GitLab workflows. The repo uses `master` as its default branch and installs skills globally under `~/.agents/skills/`.

`README.md` and `agent-matrix.md` are the source of truth for implemented skills. Current workflows cover:

- Routing: `$git-workflow`, `$git-pr`
- Branches: `$git-branch-sync`
- Issues: `$git-issue-table`, `$git-issue-details`, `$git-issue-create`
- Pull requests and merge requests: `$git-pr-table`, `$git-pr-watcher`, `$git-pr-address-comments`, `$git-pr-create`, `$git-pr-update`, `$git-pr-merge`
- CI: `$git-ci-watch`

## Settled Decisions

- Use `~/.agents/skills`, not `~/.agent/skills` or `~/.codex/skills`, for this repo's Makefile install path.
- Keep references DRY in Git under `references/git-workflow/`.
- During `make install`, copy shared references and helpers once into `~/.agents/gitSkills/` and link each installed skill back to that shared location.
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

## Live Backlog

Implement only one or two at a time. Favor work that reuses existing GitHub/GitLab target-resolution and helper patterns.

| Work | Priority | Why Next | Keep Simple Boundary |
| --- | --- | --- | --- |
| `$git-pr-review` plus single PR/MR detail helpers | High | Natural companion to `$git-pr-watcher`; covers checkout, diff, tests, and review findings. | Read-only by default; no submitted review unless explicitly asked. |
| `$git-issue-update` | Medium | Useful after issue triage finds the next action. | Require an explicit issue target; do not bulk edit. |
| `scripts/validate-skill-routing.sh` | Low | Routing examples can catch missing metadata and reference drift during `make validate`. | Start as a lightweight metadata/reference check, not a model-eval harness. |

## Future Policy Notes

- Extend `$git-workflow` only when a new command is actually implemented.
- Keep `$git-issue-table`, `$git-pr-table`, and `$git-pr-watcher` read-only.
- Keep local git state, staging, commit, push, rebase, and merge safety grounded in local `git` plus explicit user intent.
- If GitHub or GitLab MCP servers become available, prefer them only for structured read operations where they are clearly better than CLI output.

## Open Questions

- Should changelog support live here, use `$changelog-generator`, or only be referenced as a handoff?
- Should `$git-feature` exist, or should feature work stay repo-local/domain-specific?
- If GitHub/GitLab MCP servers become available, should read-only table/watcher skills prefer MCP first and use `gh`/`glab` as fallback?
- Should aliases such as `$gl-mr-table` exist, or should `git-pr-*` remain the single interface for both PRs and MRs?
- Should this eventually become a Codex plugin, or is repo checkout plus `make install` enough for personal use?
