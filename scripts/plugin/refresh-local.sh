#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/plugin/refresh-local.sh

Bump the Codex plugin cachebuster, reinstall the local plugin, and remind the
user to start a new Codex thread.

Environment:
  CODEX_PYTHON       Python wrapper for Codex helper scripts.
                     Default: ${CODEX_HOME:-~/.codex}/codex-python
  CACHEBUSTER        Optional explicit cachebuster token.
  SKIP_CACHEBUSTER   Set to 1 to reinstall without changing the version.
  MARKETPLACE_ROOT   Passed through to install-local.sh.
  MARKETPLACE_NAME   Passed through to install-local.sh.
EOF
}

die() {
  echo "$1" >&2
  exit "${2:-1}"
}

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
}

case "${1:-}" in
  -h|--help)
    usage
    exit 0
    ;;
  "")
    ;;
  *)
    die "Unknown argument: $1" 2
    ;;
esac

repo_dir="$(cd "$(script_dir)/../.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
codex_python="${CODEX_PYTHON:-$codex_home/codex-python}"
cachebuster_script="$codex_home/skills/.system/plugin-creator/scripts/update_plugin_cachebuster.py"

if [ "${SKIP_CACHEBUSTER:-0}" != "1" ]; then
  [ -x "$codex_python" ] || die "Missing Codex Python wrapper: $codex_python" 127
  [ -f "$cachebuster_script" ] || die "Missing plugin cachebuster helper: $cachebuster_script" 127

  if [ -n "${CACHEBUSTER:-}" ]; then
    "$codex_python" "$cachebuster_script" "$repo_dir" --cachebuster "$CACHEBUSTER"
  else
    "$codex_python" "$cachebuster_script" "$repo_dir"
  fi
fi

"$(script_dir)/install-local.sh"
