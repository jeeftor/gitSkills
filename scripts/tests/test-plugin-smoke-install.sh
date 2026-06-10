#!/bin/sh
set -eu

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_root="$(mktemp -d "${TMPDIR:-/tmp}/git-skills-plugin-smoke.XXXXXX")"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT HUP INT TERM

fail() {
  echo "test-plugin-smoke-install: $1" >&2
  exit 1
}

command -v codex >/dev/null 2>&1 || fail "missing required command: codex"
command -v jq >/dev/null 2>&1 || fail "missing required command: jq"

plugin_name="$(jq -r '.name' "$repo_dir/.codex-plugin/plugin.json")"
marketplace_name="git-skills-smoke"
codex_home="$tmp_root/codex-home"
marketplace_root="$tmp_root/marketplace"

[ -n "$plugin_name" ] || fail "plugin name is empty"
[ -n "$marketplace_name" ] || fail "marketplace name is empty"

mkdir -p "$codex_home"

CODEX_HOME="$codex_home" \
MARKETPLACE_ROOT="$marketplace_root" \
MARKETPLACE_NAME="$marketplace_name" \
  "$repo_dir/scripts/plugin/install-local.sh" >/dev/null

CODEX_HOME="$codex_home" codex plugin list --json \
  | jq -e --arg plugin "$plugin_name" --arg marketplace "$marketplace_name" '.installed[] | select(.name == $plugin and .marketplaceName == $marketplace)' >/dev/null \
  || fail "plugin install did not include $plugin_name@$marketplace_name"

echo "Plugin smoke install passed."
