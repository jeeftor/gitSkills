# Git Commit Reference

Use this reference when creating, amending, squashing, or recommending commit messages.

## Message Style

Match the repository's existing style before applying a generic convention.

Detection order:

1. User-provided commit message or explicit style request.
2. Project docs such as `CONTRIBUTING.md`, `AGENTS.md`, `CLAUDE.md`, `README.md`, release docs, or PR templates.
3. Recent history: `git log --oneline -20`.
4. Hook and tooling config such as `.pre-commit-config.yaml`, `prek`, commitlint, release-please, semantic-release, changelog generators, or conventional-changelog config.

Use Conventional Commits only when the repository already uses them, tooling requires them, or the user asks for them.

If hook config includes commit-message validation, inspect that before choosing or recommending the commit message.

## Conventional Commits

When Conventional Commits are appropriate, use:

```text
type(scope): summary
```

Common types include `feat`, `fix`, `docs`, `test`, `refactor`, `chore`, `build`, `ci`, and `perf`.

Keep the summary imperative, concise, and specific. Add a body only when it explains non-obvious reasoning, migration notes, breaking changes, or validation context.

## Safety

- Ask for the commit message when the change intent is ambiguous.
- Do not include local wrapper commands, machine paths, secrets, tokens, or private environment details in commit messages.
- Do not amend, squash, or rewrite existing commits unless the user explicitly asks or has already agreed to that flow.
- Do not create commits from broad staging. Follow `mutation.md` staging rules.
