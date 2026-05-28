#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/../.." && pwd)

demo_repo=$("$script_dir/make-temp-repo.sh" tiny-docs)

cd "$demo_repo"

printf '%s\n' "$ git status --short --branch"
git status --short --branch

printf '\n%s\n' "$ codex exec --ephemeral --sandbox workspace-write '\$git-workflow ...'"
codex exec \
	--ephemeral \
	--sandbox workspace-write \
	-c 'approval_policy="untrusted"' \
	"\$git-workflow In this temporary repository, decide which coordinator workflow should route a request about preparing a pull request summary before any commit, push, or PR creation. Do not modify files. Keep the final answer to the chosen skill and one sentence why."

cd "$repo_root"

if [ "${KEEP_DEMO_REPO:-0}" = "1" ]; then
	printf '\n%s\n' "Demo repository: $demo_repo"
else
	rm -rf "$demo_repo"
fi
