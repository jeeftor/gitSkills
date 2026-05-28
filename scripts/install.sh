#!/bin/sh
set -eu

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
GITSKILLS_HOME="${GITSKILLS_HOME:-$HOME/.agents/gitSkills}"
SKILLS="git-workflow git-branch-sync git-issue-table git-issue-details git-issue-create git-issue-update git-pr git-pr-table git-pr-watcher git-pr-review git-pr-address-comments git-ci-watch git-pr-create git-pr-update git-pr-merge vhs"
REFERENCE_SUBDIR="references/git-workflow"
GIT_HELPER_SUBDIR="scripts/git"
VHS_HELPER_SUBDIR="scripts/vhs"

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
  echo
  echo "Shared references and helpers will be copied once to:"
  echo "  $repo_dir/$REFERENCE_SUBDIR -> $GITSKILLS_HOME/references/git-workflow"
  echo "  $repo_dir/$GIT_HELPER_SUBDIR -> $GITSKILLS_HOME/scripts/git"
  echo "  $repo_dir/$VHS_HELPER_SUBDIR -> $GITSKILLS_HOME/scripts/vhs"

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

if [ ! -d "$repo_dir/$GIT_HELPER_SUBDIR" ]; then
  echo "Missing helper scripts: $GIT_HELPER_SUBDIR" >&2
  exit 1
fi

if [ ! -d "$repo_dir/$VHS_HELPER_SUBDIR" ]; then
  echo "Missing helper scripts: $VHS_HELPER_SUBDIR" >&2
  exit 1
fi

confirm_plan

mkdir -p "$SKILLS_DIR"
mkdir -p "$GITSKILLS_HOME/references" "$GITSKILLS_HOME/scripts"

rm -rf "${GITSKILLS_HOME:?}/references/git-workflow"
rm -rf "${GITSKILLS_HOME:?}/scripts/git"
rm -rf "${GITSKILLS_HOME:?}/scripts/vhs"
cp -R "$repo_dir/$REFERENCE_SUBDIR" "$GITSKILLS_HOME/references/git-workflow"
cp -R "$repo_dir/$GIT_HELPER_SUBDIR" "$GITSKILLS_HOME/scripts/git"
cp -R "$repo_dir/$VHS_HELPER_SUBDIR" "$GITSKILLS_HOME/scripts/vhs"

for skill in $SKILLS; do
  rm -rf "${SKILLS_DIR:?}/$skill"
  cp -R "$repo_dir/skills/$skill" "$SKILLS_DIR/$skill"
  if [ "$skill" = "vhs" ]; then
    mkdir -p "$SKILLS_DIR/$skill/scripts"
    ln -s "$GITSKILLS_HOME/scripts/vhs" "$SKILLS_DIR/$skill/scripts/vhs"
  else
    mkdir -p "$SKILLS_DIR/$skill/references"
    ln -s "$GITSKILLS_HOME/references/git-workflow" "$SKILLS_DIR/$skill/references/git-workflow"
    mkdir -p "$SKILLS_DIR/$skill/scripts"
    ln -s "$GITSKILLS_HOME/scripts/git" "$SKILLS_DIR/$skill/scripts/git"
  fi
  echo "Installed $skill"
done

echo
echo "Installed Codex Git skills into $SKILLS_DIR"
echo "Installed shared gitSkills assets into $GITSKILLS_HOME"
echo "Restart Codex to pick up new skills."
