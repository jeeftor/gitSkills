#!/bin/sh
set -eu

fixture=${1:-tiny-docs}
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
fixture_dir=$repo_root/docs/demos/fixtures/$fixture

if [ ! -d "$fixture_dir" ]; then
	printf '%s\n' "Unknown demo fixture: $fixture" >&2
	exit 1
fi

repo_dir=${DEMO_REPO_DIR:-$(mktemp -d "${TMPDIR:-/tmp}/gitskills-demo.XXXXXX")}

git init "$repo_dir" >/dev/null
cp -R "$fixture_dir/." "$repo_dir/"

(
	cd "$repo_dir"
	git checkout -b main >/dev/null 2>&1

	if ! git config user.name >/dev/null 2>&1; then
		git config user.name "Git Skills Demo"
	fi
	if ! git config user.email >/dev/null 2>&1; then
		git config user.email "demo@example.invalid"
	fi

	git add README.md docs
	git commit -m "Initial demo fixture" >/dev/null
	git switch -c feature/pr-summary >/dev/null 2>&1
	printf '\n## Proposed PR Summary\n\nExplain the documentation-only change in one paragraph.\n' >> docs/notes.md
)

printf '%s\n' "$repo_dir"
