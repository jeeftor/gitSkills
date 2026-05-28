#!/bin/sh
set -eu

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
repo_root=$(CDPATH='' cd -- "$script_dir/../.." && pwd)
cd "$repo_root"

tape_dir=${VHS_TAPE_DIR:-docs/demos/tapes}
output_dir=${VHS_OUTPUT_DIR:-docs/demos/output}

usage() {
	cat >&2 <<'EOF'
Usage: scripts/vhs/new-demo.sh NAME

Creates a starter VHS tape using deterministic repo defaults.
EOF
}

if [ "$#" -ne 1 ]; then
	usage
	exit 2
fi

name=$1
case "$name" in
	""|*/*|*..*|*[!A-Za-z0-9_.-]*)
		printf '%s\n' "Invalid demo name: $name" >&2
		exit 2
		;;
esac

mkdir -p "$tape_dir" "$output_dir"
tape=$tape_dir/$name.tape

if [ -e "$tape" ]; then
	printf '%s\n' "Tape already exists: $tape" >&2
	exit 1
fi

cat >"$tape" <<EOF
Require vhs

Output "$output_dir/$name.gif"
Screenshot "$output_dir/$name.png"

Set Shell "bash"
Set FontSize 18
Set Width 1200
Set Height 720
Set Theme "Catppuccin Mocha"

Type "printf '%s\\n' 'Record a deterministic demo here.'"
Enter
Wait+Line /Record a deterministic demo here\./
Sleep 1s
EOF

printf '%s\n' "Created $tape"
