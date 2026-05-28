#!/bin/sh
set -eu

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
SKILLS="git-workflow git-issue-table git-issue-details git-issue-create git-pr git-pr-table git-pr-watcher git-pr-address-comments git-ci-watch git-pr-create git-pr-update git-pr-merge"
REFERENCE_SUBDIR="references/git-workflow"
HELPER_SUBDIR="scripts/git"

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
}

repo_dir="$(cd "$(script_dir)/.." && pwd)"

confirm_plan() {
  echo
  echo "Codex Git Skills install/update plan"
  echo
  echo "Skills will be copied to:"
  for skill in $SKILLS; do
    echo "  $repo_dir/skills/$skill -> $SKILLS_DIR/$skill"
  done

  if [ "${ASSUME_YES:-0}" = "1" ] || [ "${CI:-0}" = "1" ]; then
    echo "Proceeding because ASSUME_YES=1 or CI=1."
    return
  fi

  printf "Press Enter to install, or Ctrl-C to abort: "
  read -r _answer
}

for skill in $SKILLS; do
  if [ ! -d "$repo_dir/skills/$skill" ]; then
    echo "Missing skill: $skill" >&2
    exit 1
  fi
done

if [ ! -d "$repo_dir/$REFERENCE_SUBDIR" ]; then
  echo "Missing shared references: $REFERENCE_SUBDIR" >&2
  exit 1
fi

if [ ! -d "$repo_dir/$HELPER_SUBDIR" ]; then
  echo "Missing helper scripts: $HELPER_SUBDIR" >&2
  exit 1
fi

confirm_plan

mkdir -p "$SKILLS_DIR"

for skill in $SKILLS; do
  rm -rf "${SKILLS_DIR:?}/$skill"
  cp -R "$repo_dir/skills/$skill" "$SKILLS_DIR/$skill"
  mkdir -p "$SKILLS_DIR/$skill/references"
  cp -R "$repo_dir/$REFERENCE_SUBDIR" "$SKILLS_DIR/$skill/references/git-workflow"
  mkdir -p "$SKILLS_DIR/$skill/scripts"
  cp -R "$repo_dir/$HELPER_SUBDIR" "$SKILLS_DIR/$skill/scripts/git"
  echo "Installed $skill"
done

echo
echo "Installed Codex Git skills into $SKILLS_DIR"
echo "Restart Codex to pick up new skills."
