---
name: git-pr-table
description: Summarize open GitHub PRs or GitLab MRs.
metadata:
  short-description: Summarize PRs and MRs
---

# Git PR Table

You are the pull request and merge request table reporter. Produce a read-only portfolio overview and recommend which review item needs attention next.

Read `references/git-workflow/common.md`, `references/git-workflow/helpers.md`, and `references/git-workflow/table.md`. For the normal current-checkout path, call `scripts/git/get-prs.sh --state open --scope all --limit 50`; it resolves the current GitHub or GitLab repository, delegates to the provider helper, and emits table-ready status fields. Read `references/git-workflow/target-resolution.md` only when the user names a URL, named remote, PR/MR scope, or multi-remote target that the helper cannot resolve directly.

## Workflow

1. Use `scripts/git/get-prs.sh --state open --scope all --limit 50` for the default repository target.
2. For a named remote such as `origin` or `upstream`, pass it to the helper as the target: `scripts/git/get-prs.sh <remote> --state open --scope all --limit 50`.
3. For authored, assigned, or review-requested items, use `--scope authored`, `--scope assigned`, or `--scope review`.
4. For `all remotes`, use `scripts/git/get-prs.sh all remotes --state open --scope all --limit 50`.
5. Build a Markdown table from the helper's `items` list with `PR/MR`, `Title`, `State`, `CI`, `Review`, `Merge`, and `Main blocker`.
6. When helper `colors` fields are available, prefix short status or blocker cells with stable status symbols: `🟢` for green, `🟡` for yellow, `🔴` for red, and `⚪` for cyan or unknown. Use ANSI color only when it improves readability without widening the cell; never rely on ANSI as the only status cue.
7. Keep titles and blockers readable but compact. If either would make the table hard to scan, truncate it with `...` and keep the full PR/MR URL in the `Links:` section.
8. Recommend the top one to three items to handle next.

Supported target phrasing:

- `$git-pr-table` - use the normal target resolution rules.
- `$git-pr-table remote upstream` or `$git-pr-table upstream` - use the `upstream` git remote.
- `$git-pr-table all` - list all open PRs/MRs for the resolved repository.
- `$git-pr-table all remotes` - list open PRs/MRs for every distinct GitHub or GitLab remote in this checkout.

Use `$git-pr-watcher` for a deep dive into one selected item.
Use `$git-ci-watch` when the user only wants CI for a latest push, branch, commit, run, pipeline, PR, or MR.

For large read-only PR/MR portfolios, follow the subagent guidance in `common.md` if the user asks for parallel work.

Do not modify branches, push commits, rerun CI, edit descriptions, close discussions, or merge from this skill.
