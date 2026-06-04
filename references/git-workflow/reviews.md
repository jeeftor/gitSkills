# Git Review Reference

Use this reference for review comments, requested changes, unresolved threads, issue comments, maintainer questions, and discussion triage.

For local PR/MR code reviews, lead with findings ordered by severity. Include file/line references, concrete evidence, and the user-visible or maintenance risk. Put open questions after findings and keep summaries brief.

For adversarial, security, abuse-case, exploitability, or high-risk PR/MR review requests, pair the normal correctness and maintainability review with `codex-security:security-diff-scan` when available. Keep the security pass read-only, scope it to the same PR, MR, branch, commit, or diff, and merge validated findings into the normal findings-first output.

When reviewing or watching an existing PR/MR, inspect repo-local PR/MR templates if description completeness matters. Compare the current body against required template sections and treat missing required content as a documentation gap or open question. Read-only workflows must not edit the PR/MR body.

## Review Classification

Classify feedback into:

- requested code change
- requested test change
- documentation or changelog request
- maintainer question
- CI failure linked from review
- security or abuse-case risk
- conflict or stale branch
- approval or ready-to-merge signal
- ambiguous feedback requiring user clarification

## GitHub Review Data

Useful commands:

- `scripts/git/get-pr.sh <number-or-url>`
- `scripts/git/gh/get-pr.sh --repo <owner/name> --number <number>` when you need the GitHub-specific `review_threads`, `unresolved_threads_count`, and `data_gaps` fields.
- `gh pr view <number> --json reviews,comments,reviewDecision,latestReviews`
- `gh pr diff <number>`
- `gh api graphql` when unresolved review thread counts or thread bodies are missing from `gh pr view`.

GitHub review threads require GraphQL for repeatable unresolved-thread data. Prefer the GitHub PR detail helper's `review_threads` and `unresolved_threads_count` fields; if it emits `data_gaps[]` for `review_threads`, report the gap as unknown rather than resolved.

## GitLab Review Data

Useful commands:

- `scripts/git/get-pr.sh <gitlab-remote> --number <iid>`
- `glab mr view <iid>`
- `glab mr diff <iid>`
- GitLab API for discussions, notes, approval state, and unresolved threads when `glab` lacks fields.

Treat "GitLab PR" as a merge request. Use `discussions` and `unresolved_discussions` from the GitLab MR helper when they are present.

## Safety

- Read-only triage should produce an action plan, not silently edit code.
- Ask before behavior changes, risky rebases, force pushes, or ambiguous reviewer feedback.
- Do not resolve threads, submit reviews, edit PR/MR bodies, or push commits unless the user explicitly asks for that mutating workflow.
- Do not check out remote review branches with a dirty local working tree unless the user explicitly accepts the risk.
