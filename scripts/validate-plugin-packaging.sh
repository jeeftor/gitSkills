#!/bin/sh
set -eu

manifest=".codex-plugin/plugin.json"

fail() {
  echo "validate-plugin-packaging: $1" >&2
  exit 1
}

[ -f "$manifest" ] || fail "missing $manifest"
command -v jq >/dev/null 2>&1 || fail "missing required command: jq"

plugin_name="$(jq -r '.name // empty' "$manifest")"
[ -n "$plugin_name" ] || fail "$manifest is missing name"

display_name="$(jq -r '.interface.displayName // empty' "$manifest")"
[ -n "$display_name" ] || fail "$manifest is missing interface.displayName"

description="$(jq -r '.description // empty' "$manifest")"
printf '%s\n' "$description" | grep -qi 'GitHub' || fail "$manifest description must mention GitHub"
printf '%s\n' "$description" | grep -qi 'GitLab' || fail "$manifest description must mention GitLab"
printf '%s\n' "$description" | grep -qi 'detect' || fail "$manifest description must mention detection"

echo "Plugin packaging metadata is valid."
