# Agent Instructions

## Skill Documentation
- Keep `SKILL.md` frontmatter descriptions concise and trigger-focused. Prefer one sentence under 25 words; allow a second short sentence only when it materially improves routing.
- Put workflow details, examples, exclusions, and long keyword lists in the skill body or references, not in the frontmatter description.
- When adding, renaming, removing, or changing the routing role of a skill, update `README.md` and `agent-matrix.md` in the same change.

## Git Workflow
- Default branch: `master`.
- Work directly on `master` unless the user explicitly asks for a separate branch.
- Before every commit, verify whether `README.md` and `agent-matrix.md` need to be updated for the change; update them in the same commit when user-facing behavior, install steps, commands, skills, helpers, workflows, or routing relationships change.
- Update `CHANGELOG.md` for every commit with a concise description of the user-visible, workflow, tooling, or documentation change.
