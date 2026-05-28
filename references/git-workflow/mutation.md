# Git Mutation Reference

Use this reference before committing, pushing, rebasing, merging, deleting branches, editing PR/MR metadata, rerunning CI, or changing issue state.

Read `commit.md` before creating commits. Read `changelog.md` when repo instructions or the requested change require a changelog update.

## Before Mutating

1. Inspect `git status --short --branch`.
2. Identify the current branch and upstream.
3. Confirm the target PR/MR/issue/run/pipeline is unambiguous.
4. Confirm the changed files are intended.
5. Run or confirm the narrowest practical verification.
6. Confirm whether repo instructions require a changelog update for the mutation.

Stop and ask when the target branch, remote, platform, or changed file set is ambiguous.

For issue mutations, inspect the current issue first with `scripts/git/get-issue.sh`, apply only the explicit one-issue update the user requested, then inspect the issue again before reporting success.

If the repo has `.pre-commit-config.yaml` or a documented `prek` workflow, prefer the repo's hook workflow before commit/push. Use `prek` over `pre-commit` when both are viable.

## Staging

- Respect `.gitignore`.
- Do not stage ignored files or local-only artifacts unless the user explicitly asks.
- Never blindly stage everything. Avoid `git add -A`, `git add .`, `git commit -a`, and broad equivalent staging commands unless the user explicitly asks for that exact behavior after seeing the file list.
- Prefer path-specific `git add <file>` after reviewing `git status --short`.
- If relevant unstaged or untracked files exist, ask whether to include them before staging.

## Commit And Push

- Do not commit directly on default branches unless the user explicitly asks.
- Do not commit or push when verification is failing unless the user explicitly accepts that status.
- Use concise commit messages that match the repository style. See `commit.md`.
- Push to the branch backing the confirmed PR/MR.
- Set upstream only when it is missing and matches the intended remote branch.
- Verify the remote PR/MR now points at the pushed commit.

## Rebase And Force Push

- Prefer normal push updates over force pushes.
- Use `--force-with-lease` only after the user agrees to an amend/rebase flow or explicitly asks.
- Stop before rebasing if the working tree is dirty or the target branch is ambiguous.

## Merge

- Merge only when the user explicitly asks.
- Verify CI, review/approval gates, unresolved discussions, draft state, conflicts, and branch protection.
- Confirm merge method when the platform supports multiple methods.
- Do not delete branches unless the user asks or repository policy clearly requires it.
