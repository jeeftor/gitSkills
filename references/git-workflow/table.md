# Git Table Output Reference

Use this reference when a skill returns a compact status table.

## Compact Tables

- Keep tables narrow enough to scan in Codex and terminal recordings.
- Prefer Markdown tables for normal assistant output because they tolerate wrapped prose better than fixed-width box tables.
- Prefer short status phrases over full sentences inside cells.
- Do not put full URLs inside tables. Use issue, PR, or MR numbers in table cells, then add raw URLs in a `Links:` section after the table.
- Keep the recommendation outside the table when it needs more than a short action phrase.
- Preserve meaningful plain text in every cell so output remains useful if ANSI color or status-symbol rendering is unavailable.

Preferred issue layout:

```text
| Issue | Title              | Updated |
|---|---|---|
| #2 | Harness smoke test | 3h ago  |

Links:
#2 https://gitlab.example.com/group/project/-/issues/2

Recommendation:
1. Inspect #2 first. It is the most recent relevant issue.
```

Preferred PR/MR layout follows the same pattern: use `#12` or `!12` in the table, then place the raw URL on its own line under `Links:` so terminals can make it clickable.

## Visual Cues

ANSI color renders in Codex assistant-authored messages, but tool output may collapse or show escape codes as raw text. Fixed-width box tables are fragile in Codex because long rows wrap and break borders.

For colored output, use Markdown tables with stable status symbols first and optional ANSI second. Symbols keep the table useful when ANSI is stripped or hard to see. Do not use HTML spans or font tags for color in Codex tables; they render as literal text. Use plain-text box tables only for short, fixed-width data where every rendered row stays comfortably under 100 visible columns.

Run this probe inside Codex when color rendering is uncertain:

```bash
scripts/git/codex-color-probe.sh
```

Color only short status or action tokens, not whole rows, titles, URLs, or long sentences.

Use these color hints consistently:

- Green (`\x1b[32m...\x1b[0m`) for good or no-action states: `Ready`, `Passing`, `Approved`, `Mergeable`, `Current`, `Resolved`, `None`, `No blocker`.
- Yellow (`\x1b[33m...\x1b[0m`) for attention states: `Draft`, `Pending`, `Review needed`, `Behind`, `Triage`, `Stale`, `Unassigned`, `Inspect`.
- Red (`\x1b[31m...\x1b[0m`) for blocking states: `Failing`, `Conflict`, `Changes requested`, `Blocked`, `Overdue`, `Needs owner`.
- Cyan (`\x1b[36m...\x1b[0m`) for neutral or unknown states: `Unknown`, `Missing`, `Skipped`, `No checks`, `No labels`, `No assignee`.

When helper JSON contains a color hint, map it to these status symbols:

| Hint | Symbol |
|---|---|
| `green` | `🟢` |
| `yellow` | `🟡` |
| `red` | `🔴` |
| `cyan` | `⚪` |
| `plain` | none |

ANSI may be added after the symbol when it improves readability:

| Hint | Prefix | Suffix |
|---|---|---|
| `green` | `\x1b[32m` | `\x1b[0m` |
| `yellow` | `\x1b[33m` | `\x1b[0m` |
| `red` | `\x1b[31m` | `\x1b[0m` |
| `cyan` | `\x1b[36m` | `\x1b[0m` |
| `plain` | none | none |

Preferred issue status pattern:

```text
| Issue | Title       | Updated |
|---|---|---|
| #19 | Color probe | 2h ago  |
```

In actual assistant output, use the real escape character rather than showing the literal `\x1b` text when ANSI is used.

## Status Symbols

Use at most one symbol in a status cell, and keep the text useful without it.

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

Do not add symbols to every cell. Prefer them in decision columns such as `CI`, `Review`, `Merge`, `Main blocker`, and `Next action`; use them in neutral metadata cells only when the helper explicitly marks the value as missing or unknown.
