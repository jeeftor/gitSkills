# Git Review Reference

Use this reference for review comments, requested changes, unresolved threads, issue comments, maintainer questions, and discussion triage.

## Review Classification

Classify feedback into:

- requested code change
- requested test change
- documentation or changelog request
- maintainer question
- CI failure linked from review
- conflict or stale branch
- approval or ready-to-merge signal
- ambiguous feedback requiring user clarification

## GitHub Review Data

Useful commands:

- `gh pr view <number> --json reviews,comments,reviewDecision,latestReviews`
- `gh pr diff <number>`
- `gh api graphql` when unresolved review thread counts or thread bodies are missing from `gh pr view`.

GitHub review threads often require GraphQL for complete unresolved-thread data. Treat missing thread data as unknown, not resolved.

## GitLab Review Data

Useful commands:

- `glab mr view <iid>`
- `glab mr diff <iid>`
- GitLab API for discussions, notes, approval state, and unresolved threads when `glab` lacks fields.

Treat "GitLab PR" as a merge request.

## Safety

- Read-only triage should produce an action plan, not silently edit code.
- Ask before behavior changes, risky rebases, force pushes, or ambiguous reviewer feedback.
- Do not resolve threads, submit reviews, edit PR/MR bodies, or push commits unless the user explicitly asks for that mutating workflow.
