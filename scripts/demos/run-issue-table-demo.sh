#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/../.." && pwd)

demo_repo=$("$script_dir/make-temp-repo.sh" tiny-docs)

cd "$demo_repo"

printf '\033[2J\033[H'
printf '%s\n' "$ codex"
sleep 1
printf '\n%s\n' "> \$git-issue-table"
sleep 1

cat <<'EOF'
Open issues for example/docs-demo:

| Issue | Title | Updated |
|---|---|---|
| #14 | Add helper smoke tests for local JSON contracts | 2h ago |
| #11 | Document completion handoff behavior | 1d ago |
| #8 | Add CI validation for repository checks | 3d ago |
| #3 | Refresh shortcut workflow matrix | 1w ago |

Links:
#14 https://github.com/example/docs-demo/issues/14
#11 https://github.com/example/docs-demo/issues/11
#8 https://github.com/example/docs-demo/issues/8
#3 https://github.com/example/docs-demo/issues/3

Recommendation:
1. Inspect #14 first because helper contract tests protect shared workflows.
2. Then #11, since completion handoff affects every mutating workflow.
3. Then #8, so local validation is visible in hosted checks.
EOF

cd "$repo_root"

if [ "${KEEP_DEMO_REPO:-0}" = "1" ]; then
	printf '\n%s\n' "Demo repository: $demo_repo"
else
	rm -rf "$demo_repo"
fi
