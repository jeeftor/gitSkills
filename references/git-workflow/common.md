# Git Workflow Common Reference

Use this lightweight reference for every `gitSkills` workflow. Read deeper references only when the task needs them:

- `target-resolution.md`: host, repository, branch, PR/MR, issue, CI target, and mixed GitHub/GitLab detection.
- `table.md`: compact table output, ANSI color, emoji, and status-token conventions.
- `helpers.md`: repo-local and installed helper script conventions.
- `github.md`: GitHub `gh` commands and GitHub API fallbacks.
- `gitlab.md`: GitLab `glab` commands and GitLab API fallbacks.
- `ci.md`: CI status normalization, logs, runs, jobs, pipelines, and read-only CI safety.
- `reviews.md`: reviews, comments, unresolved threads, discussions, and review-response triage.
- `mutation.md`: staging, commit, push, rebase, force-with-lease, merge, and branch deletion safety.
- `changelog.md`: lightweight changelog update policy and handoff to `$changelog-generator`.

## Shared Status Terms

- `CI`: passing, failing, pending, missing, or unknown.
- `Review`: approved, changes requested, review required, or unknown.
- `Merge`: mergeable, blocked, conflict, behind, or unknown.
- `Main blocker`: the shortest actionable reason work cannot proceed.

## Shared Target Phrasing

- A named remote in the prompt, such as `origin`, `upstream`, or `remote upstream`, is an explicit repository target. Resolve it with `target-resolution.md`.
- `all remotes` means inspect every distinct GitHub or GitLab repository from the local remotes for read-only overview workflows.
- Bare `all` is workflow-specific scope, such as all open issues or all open PRs/MRs for the resolved repository. Do not treat bare `all` as `all remotes`.

## Safety

- Inspect current branch, remotes, dirty state, and target PR or MR before mutating anything. Read `target-resolution.md` when target selection is not trivial.
- Respect the repository's `.gitignore`. Do not stage ignored files or local-only artifacts unless the user explicitly asks.
- Never blindly stage everything. Do not run `git add -A`, `git add .`, `git commit -a`, or broad equivalent staging commands unless the user explicitly asks for that exact behavior after seeing the file list.
- Read `mutation.md` before commit, push, rebase, merge, or branch deletion workflows.
- Do not commit, push, rebase, close, or merge unless the user asked for that mutating workflow.
- Stop before destructive branch operations or ambiguous target selection.
- Prefer platform CLIs for read operations, then API calls when summary fields are missing.

## Completion Handoff

End a completed Git workflow with the smallest useful next step when a valid follow-up is clear. Do not suggest every related skill, and do not add a generic follow-up when no Git follow-up is needed.

Use these shared handoffs:

- Use `$git-issue-details` after `$git-issue-table` when one selected issue needs a deeper read.
- Use `$git-issue-table` after closing or finishing an issue when the user wants the next issue or recent issue-table context is available.
- Use `$git-pr-watcher` after creating a PR/MR or when a PR/MR table result needs a deep dive.
- Use `$git-ci-watch` when the only remaining question is CI status.
- Use `$git-pr-address-comments` when review feedback requires local changes.
- Use `$git-pr-update` when local changes are ready to commit and push to an existing PR/MR.
- Use `$git-pr-merge` only when the PR/MR is approved, green, mergeable, and the user asked for merge handling.

If an issue-table recommendation is already known, name the next issue directly instead of asking the user to rerun the table. If the next issue is not known, suggest `$git-issue-table` as the smallest next step.

Keep handoff details centralized here and in `agent-matrix.md`. Leaf skills may name their immediate natural next skill, but they should not duplicate a full handoff list. When adding, removing, or rerouting a workflow edge, update both this section and `agent-matrix.md` when the handoff changes.

If no Git follow-up is needed, say so briefly.

## Subagents And Parallel Work

Use subagents only when the user explicitly asks for subagents, delegation, or parallel work, or when a read-only investigation is large enough that splitting evidence is clearly useful.

Good subagent tasks:

- Split a long PR/MR list into non-overlapping groups for summary fields and blockers.
- Inspect CI logs while the main agent inspects review comments and discussions.
- Inspect GitHub and GitLab signals separately when a repo legitimately uses both.
- Compare branch freshness, conflicts, and mergeability while another read-only pass reviews comments.

Keep final prioritization, decisions, and user-facing recommendations in the main agent. Do not delegate commits, pushes, rebases, force pushes, merges, branch deletion, PR/MR edits, issue edits, CI reruns, or CI cancellations.

When using subagents, give each one:

- the target skill name
- the exact repo, PR/MR, issue, run, pipeline, branch, or commit to inspect
- a read-only scope
- the fields to report back

Do not run parallel agents in the same working tree when they may edit files or branch state.
