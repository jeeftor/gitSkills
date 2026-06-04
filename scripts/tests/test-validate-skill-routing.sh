#!/bin/sh
set -eu

repo_dir="$(cd "$(dirname "$0")/../.." && pwd)"
tmp_root="$repo_dir/.test-tmp/validate-skill-routing.$$"

cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT HUP INT TERM

make_fixture() {
  case_dir="$1"
  mkdir -p "$case_dir/skills" "$case_dir/references/git-workflow" "$case_dir/scripts/git"
  : >"$case_dir/README.md"
  : >"$case_dir/agent-matrix.md"

  for skill in git-workflow git-pr git-ci-watch git-issue-table; do
    mkdir -p "$case_dir/skills/$skill"
    cat >"$case_dir/skills/$skill/SKILL.md" <<EOF
---
name: $skill
description: Route test fixture workflows.
---

# $skill
EOF
  done
}

expect_validation_failure() {
  case_name="$1"
  expected="$2"
  case_dir="$tmp_root/$case_name"

  if (cd "$case_dir" && "$repo_dir/scripts/validate-skill-routing.sh" >out.txt 2>err.txt); then
    echo "Expected $case_name to fail validation" >&2
    cat "$case_dir/out.txt" >&2
    exit 1
  fi

  if ! grep -q "$expected" "$case_dir/err.txt"; then
    echo "Expected $case_name failure to mention: $expected" >&2
    cat "$case_dir/err.txt" >&2
    exit 1
  fi
}

mkdir -p "$tmp_root"

star_case="$tmp_root/starred-frontmatter"
make_fixture "$star_case"
mkdir -p "$star_case/skills/git-hidden-entry"
cat >"$star_case/skills/git-hidden-entry/SKILL.md" <<'EOF'
---
name: git-hidden-entry
description: ⭐ Hidden entry point.
---

# Hidden Entry
EOF
expect_validation_failure "starred-frontmatter" "not in the intentional entry-point set"

word_count_case="$tmp_root/description-word-count"
make_fixture "$word_count_case"
mkdir -p "$word_count_case/skills/git-too-long"
cat >"$word_count_case/skills/git-too-long/SKILL.md" <<'EOF'
---
name: git-too-long
description: one two three four five six seven eight nine ten eleven twelve thirteen fourteen fifteen sixteen seventeen eighteen nineteen twenty twentyone twentytwo twentythree twentyfour twentyfive twentysix
---

# Too Long
EOF
expect_validation_failure "description-word-count" "description must be 25 words or fewer"

echo "Skill routing validation edge cases are covered."
