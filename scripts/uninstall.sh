#!/bin/sh
set -eu

SKILLS_DIR="${SKILLS_DIR:-$HOME/.agents/skills}"
SKILLS="git-workflow git-issue-table git-pr git-pr-table git-pr-watcher git-pr-address-comments git-ci-watch git-pr-create git-pr-update git-pr-merge"

confirm_plan() {
  echo
  echo "Codex Git Skills uninstall plan"
  echo
  echo "Skill directories will be removed:"
  for skill in $SKILLS; do
    echo "  $SKILLS_DIR/$skill"
  done

  if [ "${ASSUME_YES:-0}" = "1" ] || [ "${CI:-0}" = "1" ]; then
    echo "Proceeding because ASSUME_YES=1 or CI=1."
    return
  fi

  printf "Press Enter to continue or Ctrl-C to abort: "
  read -r _answer
}

confirm_plan

for skill in $SKILLS; do
  rm -rf "${SKILLS_DIR:?}/$skill"
  echo "Removed $skill"
done

echo
echo "Uninstalled Codex Git skills. Restart Codex to refresh the skill list."
