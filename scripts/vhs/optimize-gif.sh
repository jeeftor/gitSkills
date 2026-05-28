#!/bin/sh
set -eu

lossy=${VHS_GIF_LOSSY:-20}
output=

usage() {
	cat >&2 <<'EOF'
Usage: scripts/vhs/optimize-gif.sh [--lossy N] [--output FILE] FILE.gif

Optimizes a GIF with gifsicle when available. With no --output, the input is
replaced only if the optimized file is smaller.
EOF
}

while [ "$#" -gt 0 ]; do
	case "$1" in
		--lossy)
			if [ "$#" -lt 2 ]; then
				usage
				exit 2
			fi
			lossy=$2
			shift 2
			;;
		--output)
			if [ "$#" -lt 2 ]; then
				usage
				exit 2
			fi
			output=$2
			shift 2
			;;
		--help|-h)
			usage
			exit 0
			;;
		-*)
			usage
			exit 2
			;;
		*)
			break
			;;
	esac
done

if [ "$#" -ne 1 ]; then
	usage
	exit 2
fi

input=$1
if [ ! -f "$input" ]; then
	printf '%s\n' "GIF not found: $input" >&2
	exit 1
fi

if ! command -v gifsicle >/dev/null 2>&1; then
	printf '%s\n' "Skipping GIF optimization because gifsicle is not installed: $input"
	exit 0
fi

if [ -z "$output" ]; then
	output=$input
fi

tmp=${output}.tmp.$$
trap 'rm -f "$tmp"' EXIT HUP INT TERM

original_size=$(wc -c <"$input" | tr -d ' ')
gifsicle -O3 --lossy="$lossy" "$input" -o "$tmp"
optimized_size=$(wc -c <"$tmp" | tr -d ' ')

if [ "$optimized_size" -lt "$original_size" ]; then
	mv "$tmp" "$output"
	printf '%s\n' "Optimized $output: $original_size -> $optimized_size bytes"
else
	if [ "$output" != "$input" ]; then
		cp "$input" "$output"
	fi
	printf '%s\n' "Kept original $input: optimized candidate was not smaller ($original_size <= $optimized_size bytes)"
fi
