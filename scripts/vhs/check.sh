#!/bin/sh
set -eu

missing=0

need_required() {
	if ! command -v "$1" >/dev/null 2>&1; then
		printf '%s\n' "Missing required command: $1" >&2
		missing=1
	else
		printf '%s\n' "Found required command: $1"
	fi
}

need_optional() {
	if command -v "$1" >/dev/null 2>&1; then
		printf '%s\n' "Found optional command: $1"
	else
		printf '%s\n' "Optional command not found: $1${2:+ ($2)}"
	fi
}

need_required vhs
need_required ffmpeg
need_optional gifsicle
need_optional ttyd "some VHS installations need this for rendering"

if [ "$missing" -ne 0 ]; then
	cat >&2 <<'EOF'

Install guidance:
  brew install vhs ffmpeg gifsicle

Docker fallback:
  docker run --rm -v "$PWD:/vhs" ghcr.io/charmbracelet/vhs <cassette>.tape
EOF
	exit "$missing"
fi
