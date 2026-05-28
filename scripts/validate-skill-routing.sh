#!/bin/sh
set -eu

allowed_starred_skills="git-workflow git-pr git-ci-watch git-issue-table"
status=0

fail() {
  echo "validate-skill-routing: $1" >&2
  status=1
}

contains_word() {
  needle="$1"
  haystack="$2"
  for word in $haystack; do
    if [ "$word" = "$needle" ]; then
      return 0
    fi
  done
  return 1
}

skill_exists() {
  [ -f "skills/$1/SKILL.md" ]
}

extract_skill_refs() {
  # shellcheck disable=SC2016
  grep -Eoh '\$(git-[A-Za-z0-9-]+|vhs)' "$@" 2>/dev/null | sed 's/^\$//' | sort -u || true
}

extract_reference_refs() {
  grep -Eoh 'references/git-workflow/[A-Za-z0-9_.-]+\.md' "$@" 2>/dev/null | sort -u || true
}

extract_helper_refs() {
  grep -Eoh 'scripts/git/[A-Za-z0-9_./-]+\.sh' "$@" 2>/dev/null | sort -u || true
}

validate_skill_frontmatter() {
  skill_dir="$1"
  skill_name="$(basename "$skill_dir")"
  skill_file="$skill_dir/SKILL.md"

  [ -f "$skill_file" ] || {
    fail "$skill_dir is missing SKILL.md"
    return
  }

  first_line="$(sed -n '1p' "$skill_file")"
  [ "$first_line" = "---" ] || fail "$skill_file must start with YAML frontmatter"

  name_line="$(sed -n '/^name: /{p;q;}' "$skill_file")"
  description_line="$(sed -n '/^description: /{p;q;}' "$skill_file")"
  closing_line="$(awk 'NR > 1 && NR <= 20 && $0 == "---" {print NR; exit}' "$skill_file")"

  [ "$name_line" = "name: $skill_name" ] || fail "$skill_file name must match directory '$skill_name'"
  [ -n "$description_line" ] || fail "$skill_file is missing frontmatter description"
  [ -n "$closing_line" ] || fail "$skill_file frontmatter must close within the first 20 lines"

  description="${description_line#description: }"
  description_len="$(printf '%s' "$description" | wc -c | tr -d ' ')"
  if [ "$description_len" -gt 120 ]; then
    fail "$skill_file description is longer than 120 characters"
  fi
}

validate_skill_reference() {
  ref="$1"
  source="$2"
  if ! skill_exists "$ref"; then
    fail "$source references missing skill '$ref'"
  fi
}

validate_reference_file() {
  ref="$1"
  source="$2"
  if [ ! -f "$ref" ]; then
    fail "$source references missing shared reference '$ref'"
  fi
}

validate_helper_file() {
  ref="$1"
  source="$2"
  if [ ! -f "$ref" ]; then
    fail "$source references missing helper '$ref'"
  fi
}

validate_starred_skill() {
  skill="$1"
  source="$2"
  if ! contains_word "$skill" "$allowed_starred_skills"; then
    fail "$source marks '$skill' as starred, but it is not in the intentional entry-point set"
  fi
  grep -q "\`\\\$$skill\`" README.md || fail "$source marks '$skill' as starred, but README.md does not list it"
  grep -q "\\\$$skill" agent-matrix.md || fail "$source marks '$skill' as starred, but agent-matrix.md does not reference it"
}

for skill_dir in skills/*; do
  [ -d "$skill_dir" ] || continue
  validate_skill_frontmatter "$skill_dir"
done

for skill in $allowed_starred_skills; do
  skill_exists "$skill" || fail "intentional starred skill '$skill' is missing"
done

# shellcheck disable=SC2016
for skill in $(grep -Eoh '⭐ `\$git-[A-Za-z0-9-]+`|description: ⭐ .*' README.md skills/*/SKILL.md 2>/dev/null | grep -Eoh '\$git-[A-Za-z0-9-]+' | sed 's/^\$//' | sort -u || true); do
  validate_starred_skill "$skill" "starred skill metadata"
done

for source in README.md agent-matrix.md skills/*/SKILL.md; do
  [ -f "$source" ] || continue
  for ref in $(extract_skill_refs "$source"); do
    validate_skill_reference "$ref" "$source"
  done
done

for source in README.md agent-matrix.md skills/*/SKILL.md references/git-workflow/*.md; do
  [ -f "$source" ] || continue
  for ref in $(extract_reference_refs "$source"); do
    validate_reference_file "$ref" "$source"
  done
  for ref in $(extract_helper_refs "$source"); do
    validate_helper_file "$ref" "$source"
  done
done

if [ "$status" -ne 0 ]; then
  exit "$status"
fi

echo "Skill routing references are valid."
