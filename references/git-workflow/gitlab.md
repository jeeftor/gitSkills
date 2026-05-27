# GitLab Workflow Reference

Use this reference when remotes, URLs, or user input identify GitLab.

## Commands

- Current user: `glab api user`
- List MRs: `glab mr list`
- View MR: `glab mr view <iid>`
- MR checks and pipeline details: `glab pipeline list` and `glab pipeline view`
- List issues: `glab issue list`

Use the GitLab API when approval status, discussions, merge train state, or pipeline details are missing from `glab`.

## Merge Request Notes

GitLab merge requests can have draft state, approvals, discussions, pipelines, merge trains, squash settings, and branch protection. If the user says "GitLab PR", treat that as a merge request.

