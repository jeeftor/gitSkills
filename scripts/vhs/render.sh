#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/../.." && pwd)
cd "$repo_root"

tape_dir=${VHS_TAPE_DIR:-docs/demos/tapes}
output_dir=${VHS_OUTPUT_DIR:-docs/demos/output}
demo=${DEMO:-git-workflow}
mode=one
tape_path=

usage() {
	cat >&2 <<'EOF'
Usage: scripts/vhs/render.sh [--check|--validate|--all|--demo NAME|TAPE]

Environment:
  VHS_TAPE_DIR     Directory containing .tape files. Default: docs/demos/tapes
  VHS_OUTPUT_DIR   Directory for generated artifacts. Default: docs/demos/output
  VHS_GIF_LOSSY    gifsicle lossy value. Default: 20
EOF
}

case "${1:-}" in
	--check)
		mode=check
		shift
		;;
	--validate)
		mode=validate
		shift
		;;
	--all)
		mode=all
		shift
		;;
	--demo)
		if [ "$#" -lt 2 ]; then
			usage
			exit 2
		fi
		mode=one
		demo=$2
		if [ -z "$demo" ]; then
			demo=git-workflow
		fi
		shift 2
		;;
	--help|-h)
		usage
		exit 0
		;;
	"")
		mode=one
		;;
	-*)
		usage
		exit 2
		;;
	*)
		mode=one
		tape_path=$1
		shift
		;;
esac

if [ "$#" -ne 0 ]; then
	usage
	exit 2
fi

check_tools() {
	"$script_dir/check.sh"
}

render_failure_guidance() {
	cat >&2 <<'EOF'

VHS rendering failed. If the tape validates but rendering cannot launch a browser,
verify that the local VHS rendering stack is complete.

Install guidance:
  brew install vhs ffmpeg ttyd

Optional GIF optimization:
  brew install gifsicle

Docker fallback:
  docker run --rm -v "$PWD:/vhs" ghcr.io/charmbracelet/vhs <cassette>.tape
EOF
}

list_tapes() {
	found=0
	for tape in "$tape_dir"/*.tape; do
		if [ -f "$tape" ]; then
			found=1
			printf '%s\n' "$tape"
		fi
	done

	if [ "$found" -eq 0 ]; then
		printf '%s\n' "No tape files found in $tape_dir" >&2
		return 1
	fi
}

artifact_paths() {
	tape=$1
	awk '
		/^[[:space:]]*#/ { next }
		/^[[:space:]]*(Output|Screenshot)[[:space:]]+/ {
			$1 = ""
			sub(/^[[:space:]]+/, "")
			sub(/[[:space:]]+#.*$/, "")
			gsub(/^"/, "")
			gsub(/"$/, "")
			if ($0 != "" && $0 !~ /\/$/) {
				print $0
			}
		}
	' "$tape"
}

report_artifacts() {
	tape=$1
	artifact_paths "$tape" | while IFS= read -r artifact; do
		if [ -f "$artifact" ]; then
			size=$(wc -c <"$artifact" | tr -d ' ')
			printf '%s\n' "Artifact: $artifact ($size bytes)"
		fi
	done
}

optimize_gifs() {
	tape=$1
	artifact_paths "$tape" | while IFS= read -r artifact; do
		case "$artifact" in
			*.gif)
				if [ -f "$artifact" ]; then
					"$script_dir/optimize-gif.sh" "$artifact"
				fi
				;;
		esac
	done
}

validate_tapes() {
	check_tools
	list_tapes >/dev/null
	vhs validate "$tape_dir"/*.tape
}

render_one() {
	tape=$1
	if [ ! -f "$tape" ]; then
		printf '%s\n' "Tape not found: $tape" >&2
		exit 1
	fi

	check_tools
	mkdir -p "$output_dir"
	if ! vhs "$tape"; then
		render_failure_guidance
		exit 1
	fi
	optimize_gifs "$tape"
	report_artifacts "$tape"
}

render_all() {
	check_tools
	mkdir -p "$output_dir"
	list_tapes | while IFS= read -r tape; do
		if ! vhs "$tape"; then
			render_failure_guidance
			exit 1
		fi
		optimize_gifs "$tape"
		report_artifacts "$tape"
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
		render_all
		;;
	one)
		if [ -z "$tape_path" ]; then
			tape_path=$tape_dir/$demo.tape
		fi
		render_one "$tape_path"
		;;
esac
