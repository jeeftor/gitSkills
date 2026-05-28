# PR/MR Description Reference

Use this reference when composing a GitHub pull request body, GitLab merge request description, or dense PR/MR description guidance.

## Shape

Prefer preserving project templates and repo-local contribution guidance over generated prose. Fill required template sections instead of deleting them, and keep contribution checklist wording intact unless the local instructions say otherwise.

Keep simple PRs and MRs concise. Use short prose or bullets when the change has only a few related facts and a table would add visual noise.

Use Markdown tables when dense structured details are clearer as rows and columns, especially for:

- verification results
- affected areas or components
- compatibility, platform, or migration status
- follow-up work or rollout items

## Table Rendering

Make tables render cleanly on GitHub and GitLab:

- Put a blank line before and after each table.
- Use a normal header and separator row, such as `| Check | Result | Notes |` followed by `| --- | --- | --- |`.
- Keep cells short; move long reasoning below the table.
- Avoid multiline cells, nested lists, and raw full URLs in table cells.
- Escape literal pipe characters in cells as `\|`.

## Examples

```markdown
| Check | Result | Notes |
| --- | --- | --- |
| `make validate` | Pass | Validates skill metadata and shell syntax. |
| Manual PR preview | Pass | Table renders on GitHub and GitLab. |
```

```markdown
| Area | Change | Impact |
| --- | --- | --- |
| PR description | Adds table guidance | Clearer dense review context. |
| Templates | Preserved | Existing project requirements remain intact. |
```

```markdown
| Platform | Status | Notes |
| --- | --- | --- |
| GitHub | Supported | Standard Markdown tables render in PR bodies. |
| GitLab | Supported | Standard Markdown tables render in MR descriptions. |
```

```markdown
| Follow-up | Owner | Timing |
| --- | --- | --- |
| Watch CI | Author | After push |
| Address review comments | Author | During review |
```
