#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH= cd -- "$script_dir/../.." && pwd)
cd "$repo_root"

mode=record
demo=${DEMO:-git-workflow}

case "${1:-}" in
	--check)
		mode=check
		;;
	--validate)
		mode=validate
		;;
	--all)
		mode=all
		;;
	--demo)
		demo=${2:-$demo}
		;;
	"")
		;;
	*)
		demo=$1
		;;
esac

missing=0

need_command() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf '%s\n' "Missing required command: $1" >&2
		missing=1
	fi
}

check_tools() {
	missing=0
	need_command git
	need_command codex
	need_command vhs
	need_command ffmpeg

	if command -v ttyd >/dev/null 2>&1; then
		printf '%s\n' "Found optional command: ttyd"
	else
		printf '%s\n' "Optional command not found: ttyd"
	fi

	return "$missing"
}

validate_tapes() {
	check_tools
	vhs validate docs/demos/tapes/*.tape
}

record_one() {
	tape=docs/demos/tapes/$demo.tape
	if [ ! -f "$tape" ]; then
		printf '%s\n' "Unknown demo tape: $demo" >&2
		exit 1
	fi

	check_tools
	mkdir -p docs/demos/output
	vhs "$tape"
}

record_all() {
	check_tools
	mkdir -p docs/demos/output
	for tape in docs/demos/tapes/*.tape; do
		vhs "$tape"
	done
}

case "$mode" in
	check)
		check_tools
		;;
	validate)
		validate_tapes
		;;
	all)
		record_all
		;;
	record)
		record_one
		;;
esac
