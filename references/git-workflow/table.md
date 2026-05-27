# Git Table Output Reference

Use this reference when a skill returns a compact status table.

## Compact Tables

- Keep tables narrow enough to scan in Codex and terminal recordings.
- Prefer short status phrases over full sentences inside cells.
- Do not put full URLs inside tables. Use issue, PR, or MR numbers in table cells, then add raw URLs in a `Links:` section after the table.
- Keep the recommendation outside the table when it needs more than a short action phrase.
- Preserve meaningful plain text in every cell so output remains useful if ANSI color or emoji rendering is unavailable.

Preferred issue layout:

```text
| Issue | Title              | Labels                      | Assignee    | Updated          | Next action |
|---|---|---|---|---|---|
| #2 | Harness smoke test | board:harness, harness:done | No assignee | 2026-05-27 15:17 | Inspect |

Links:
#2 https://gitlab.example.com/group/project/-/issues/2

Recommendation:
1. Inspect #2 first. It has the only action item.
```

Preferred PR/MR layout follows the same pattern: use `#12` or `!12` in the table, then place the raw URL on its own line under `Links:` so terminals can make it clickable.

## Visual Cues

ANSI color is the primary visual cue when the surface supports it. Emoji is optional and should be used only for high-signal status cells.

Color only short status or action tokens, not whole rows, titles, URLs, or long sentences.

- Green (`\x1b[32m...\x1b[0m`) for good or no-action states: `Ready`, `Passing`, `Approved`, `Mergeable`, `Current`, `None`, `No blocker`.
- Yellow (`\x1b[33m...\x1b[0m`) for attention states: `Draft`, `Pending`, `Review needed`, `Behind`, `Triage`, `Stale`, `Unassigned`, `Inspect`.
- Red (`\x1b[31m...\x1b[0m`) for blocking states: `Failing`, `Conflict`, `Changes requested`, `Blocked`, `Overdue`, `Needs owner`.
- Cyan (`\x1b[36m...\x1b[0m`) for neutral or unknown states: `Unknown`, `Missing`, `Skipped`, `No labels`, `No assignee`.

## Emoji

Use at most one emoji in a status cell, and keep the text useful without it.

- `✅` for good or no-action states.
- `⚠️` for attention states.
- `❌` for blocking states.
- `ℹ️` for neutral or unknown states.

Preferred combined style:

```text
✅ \x1b[32mPassing\x1b[0m
⚠️ \x1b[33mReview needed\x1b[0m
❌ \x1b[31mBlocked\x1b[0m
ℹ️ \x1b[36mUnknown\x1b[0m
```

Do not add emoji to every cell. Prefer them in decision columns such as `CI`, `Review`, `Merge`, `Main blocker`, and `Next action`.
