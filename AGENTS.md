# Agent Instructions

## Skill Documentation
- Keep `SKILL.md` frontmatter descriptions concise and trigger-focused. Prefer one sentence under 25 words; allow a second short sentence only when it materially improves routing.
- Put workflow details, examples, exclusions, and long keyword lists in the skill body or references, not in the frontmatter description.
- When adding, renaming, removing, or changing the routing role of a skill, update `README.md` and `agent-matrix.md` in the same change.

## Helper Scripts
- Prefer helper scripts for repeatable Git, GitHub, and GitLab detection, data collection, and normalization. More script coverage should mean fewer agent-side setup commands and faster responses.
- If a skill repeatedly needs three or more commands to resolve the same target, add or improve a helper script so the common path becomes one command.
- Keep provider-specific helpers callable directly, and put cross-provider target detection in thin wrapper scripts when that reduces agent orchestration.
- Keep helper output machine-readable by default, especially JSON for table and status workflows, with enough fields for Codex to explain recommendations without extra API calls.
- Include plain status values first; use color only for human-facing output or as explicit color hint fields so Codex can preserve the meaning in final responses.

## Git Workflow
- Default branch: `master`.
- Work directly on `master` unless the user explicitly asks for a separate branch.
- Before every commit, verify whether `README.md` and `agent-matrix.md` need to be updated for the change; update them in the same commit when user-facing behavior, install steps, commands, skills, helpers, workflows, or routing relationships change.
- Update `CHANGELOG.md` for every commit with a concise description of the user-visible, workflow, tooling, or documentation change.
