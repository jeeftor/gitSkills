#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/plugin/install-local.sh

Install this checkout as a local Codex plugin through a generated marketplace.

Environment:
  MARKETPLACE_ROOT   Marketplace root to create or update.
                     Default: ~/.agents/git-skills-marketplace
  MARKETPLACE_NAME   Marketplace name written into marketplace.json.
                     Default: git-skills-local
  FORCE              Replace an existing non-symlink plugin path when set to 1.
EOF
}

die() {
  echo "$1" >&2
  exit "${2:-1}"
}

require_command() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Missing required command: $1" 127
  fi
}

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
}

repo_dir="$(cd "$(script_dir)/../.." && pwd)"
manifest="$repo_dir/.codex-plugin/plugin.json"

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

require_command codex
require_command jq

[ -f "$manifest" ] || die "Missing plugin manifest: $manifest" 2

plugin_name="$(jq -r '.name // empty' "$manifest")"
[ -n "$plugin_name" ] || die "Plugin manifest is missing name" 2

marketplace_name="${MARKETPLACE_NAME:-git-skills-local}"
marketplace_root="${MARKETPLACE_ROOT:-$HOME/.agents/git-skills-marketplace}"
marketplace_file="$marketplace_root/.agents/plugins/marketplace.json"
plugin_link="$marketplace_root/plugins/$plugin_name"

mkdir -p "$marketplace_root/.agents/plugins" "$marketplace_root/plugins"

if [ -e "$plugin_link" ] || [ -L "$plugin_link" ]; then
  if [ -L "$plugin_link" ]; then
    rm -f "$plugin_link"
  elif [ "${FORCE:-0}" = "1" ]; then
    rm -rf "$plugin_link"
  else
    die "Plugin path already exists and is not a symlink: $plugin_link. Set FORCE=1 to replace it." 2
  fi
fi

ln -s "$repo_dir" "$plugin_link"

jq -n \
  --arg marketplace "$marketplace_name" \
  --arg plugin "$plugin_name" \
  '{
    name: $marketplace,
    interface: {displayName: "Git Skills"},
    plugins: [
      {
        name: $plugin,
        source: {source: "local", path: ("./plugins/" + $plugin)},
        policy: {installation: "AVAILABLE", authentication: "ON_INSTALL"},
        category: "Productivity"
      }
    ]
  }' >"$marketplace_file"

codex plugin marketplace add "$marketplace_root" >/dev/null
codex plugin add "$plugin_name@$marketplace_name" >/dev/null

echo "Installed $plugin_name@$marketplace_name from $repo_dir"
echo "Marketplace root: $marketplace_root"
echo "Start a new Codex thread to use the updated plugin."
