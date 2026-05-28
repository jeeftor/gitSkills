# gitSkills Plan

Repository: https://github.com/jeeftor/gitSkills

## Current State

`gitSkills` is a personal/global Codex skill bundle for reusable Git, GitHub, and GitLab workflows. The repo uses `master` as its default branch.

`README.md` and `agent-matrix.md` are the source of truth for implemented skills and routing. Shared workflow references live under `references/git-workflow/`, and helper scripts live under `scripts/git/`.

Install from a checkout with:

```bash
make install
```

The installer copies skills into `~/.agents/skills/`, copies shared references and helpers once into `~/.agents/gitSkills/`, and links each installed skill back to that shared location. Validate changes with:

```bash
make validate
```

Restart Codex after installing or updating skills.

## Settled Decisions

- Use `gh` for GitHub workflows and `glab` for GitLab workflows.
- Keep frontmatter descriptions concise and mark only primary entry-point skills with `⭐`.
- Keep table, watcher, and review-inspection workflows read-only by default.
- Keep mutations grounded in local Git state, explicit user intent, repo `.gitignore`, path-specific staging, and the safety guidance in `references/git-workflow/mutation.md`.
- Do not use `allowed-tools` frontmatter yet; client support is still too variable.
- Do not make HA skills depend on `gitSkills`; HA-specific workflows stay in `agentSkills`.
- Do not add `$git-feature` yet; feature work should compose existing issue, branch, commit, and PR workflows until a narrower repeated workflow emerges.
- Do not add provider-specific aliases such as `$gl-mr-table` yet; `git-pr-*` remains the single interface for GitHub PRs and GitLab MRs.
- Do not package gitSkills as a Codex plugin yet; checkout plus `make install` remains the supported personal workflow until distribution or update friction justifies a plugin.
- Changelog support lives in `references/git-workflow/changelog.md`; use `$changelog-generator` only for explicit release-note or generated-changelog requests.

## Roadmap

Tracked implementation backlog lives in GitHub issues. Keep this file compact: when work becomes concrete, file or update an issue; when a command or helper is implemented, move durable guidance into `README.md`, `agent-matrix.md`, `references/git-workflow/`, or the relevant `SKILL.md`.

During normal use, watch for:

- trigger ambiguity or wrong skill routing
- missing target resolution for branches, remotes, PR/MR numbers, URLs, and mixed GitHub/GitLab repositories
- CI gaps around checks, runs, pipelines, jobs, logs, retry/rerun wording, and skipped or missing states
- mutation safety gaps around commits, pushes, rebases, force-with-lease, merges, branch deletion, and default branch protection
- output quality issues such as verbose tables, missing blockers, or weak next-action recommendations
- reference loading that reads too much context or misses the right host-specific guidance

## Open Question

- If GitHub/GitLab MCP servers become available, should read-only table/watcher skills prefer MCP first and use `gh`/`glab` as fallback? See #42.
