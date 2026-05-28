# Git Changelog Reference

Use this reference when a repository expects changelog updates as part of normal Git work.

## Decision

`gitSkills` does not provide a dedicated changelog skill. Mutation workflows should follow repo-local instructions for small changelog entries and hand off to `$changelog-generator` only when the user asks for release notes, changelog generation, or broader release-writing help.

## Workflow

1. Check repo instructions such as `AGENTS.md`, `CONTRIBUTING.md`, release docs, or an existing changelog format.
2. Update the changelog in the same change when the repo requires it for user-visible, workflow, tooling, or documentation changes.
3. Keep entries concise and consistent with the existing changelog section.
4. Do not invent release versions or dates unless the repo instructions or user request provide them.
5. If the requested output is a full release note or generated changelog, use `$changelog-generator` when available instead of duplicating that workflow here.

## Safety

- Treat changelog edits like any other changed file: stage them explicitly and mention them in the summary.
- Do not rewrite historical changelog entries unless the user explicitly asks.
- If the changelog requirement is unclear, mention the uncertainty before committing.
