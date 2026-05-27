#!/bin/sh
set -eu

usage() {
  cat <<'EOF'
Usage: scripts/git/codex-color-probe.sh [--mode quick|ansi|markdown|html|labels|all]

Print rendering samples that can be run inside Codex to see which color and
status-marker formats survive the current surface.
EOF
}

section() {
  printf '\n## %s\n\n' "$1"
}

ansi_samples() {
  esc="$(printf '\033')"
  reset="${esc}[0m"

  section "ANSI SGR"
  printf '%-18s %s%s%s\n' "green-32" "${esc}[32m" "Passing" "$reset"
  printf '%-18s %s%s%s\n' "yellow-33" "${esc}[33m" "Pending" "$reset"
  printf '%-18s %s%s%s\n' "red-31" "${esc}[31m" "Failing" "$reset"
  printf '%-18s %s%s%s\n' "cyan-36" "${esc}[36m" "Unknown" "$reset"
  printf '%-18s %s%s%s\n' "bold" "${esc}[1m" "Needs owner" "$reset"
  printf '%-18s %s%s%s\n' "dim" "${esc}[2m" "No labels" "$reset"

  section "ANSI 256 And Truecolor"
  printf '%-18s %s%s%s\n' "256-green-34" "${esc}[38;5;34m" "Ready" "$reset"
  printf '%-18s %s%s%s\n' "256-yellow-220" "${esc}[38;5;220m" "Inspect" "$reset"
  printf '%-18s %s%s%s\n' "true-red" "${esc}[38;2;220;38;38m" "Blocked" "$reset"
  printf '%-18s %s%s%s\n' "true-cyan" "${esc}[38;2;8;145;178m" "Missing" "$reset"
}

markdown_samples() {
  section "Markdown"
  printf '%s\n' '- **Passing**'
  printf '%s%s%s%s\n' '- ' "\`" "Pending" "\`"
  printf '%s\n' '- <span style="color:#16a34a">Passing</span>'
  printf '%s\n' '- <span style="color:#ca8a04">Pending</span>'
  printf '%s\n' '- <span style="color:#dc2626">Failing</span>'
  printf '%s\n' '- <span style="color:#0891b2">Unknown</span>'
}

html_samples() {
  section "HTML"
  printf '%s\n' '<font color="green">Passing</font>'
  printf '%s\n' '<font color="orange">Pending</font>'
  printf '%s\n' '<font color="red">Failing</font>'
  printf '%s\n' '<font color="teal">Unknown</font>'
}

label_samples() {
  section "Plain Labels"
  printf '%-18s %s\n' "[green]" "Passing"
  printf '%-18s %s\n' "[yellow]" "Pending"
  printf '%-18s %s\n' "[red]" "Failing"
  printf '%-18s %s\n' "[cyan]" "Unknown"

  section "Color Hint JSON"
  printf '%s\n' '{"status":"Passing","color":"green"}'
  printf '%s\n' '{"status":"Pending","color":"yellow"}'
  printf '%s\n' '{"status":"Failing","color":"red"}'
  printf '%s\n' '{"status":"Unknown","color":"cyan"}'
}

quick_samples() {
  esc="$(printf '\033')"
  reset="${esc}[0m"

  section "Quick Color Probe"
  printf '%-14s %s%s%s\n' "ansi-green" "${esc}[32m" "Passing" "$reset"
  printf '%-14s %s%s%s\n' "ansi-yellow" "${esc}[33m" "Pending" "$reset"
  printf '%-14s %s%s%s\n' "ansi-red" "${esc}[31m" "Failing" "$reset"
  printf '%-14s %s%s%s\n' "ansi-cyan" "${esc}[36m" "Unknown" "$reset"
  printf '%-14s %s\n' "markdown" "**Passing** and \`Pending\`"
  printf '%-14s %s\n' "html-span" '<span style="color:#16a34a">Passing</span>'
  printf '%-14s %s\n' "plain-label" "[red] Failing"
  printf '%-14s %s\n' "json-hint" '{"status":"Passing","color":"green"}'
}

mode="quick"

while [ "$#" -gt 0 ]; do
  case "$1" in
    --mode)
      mode="${2:?missing value for --mode}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

case "$mode" in
  quick)
    quick_samples
    ;;
  ansi)
    ansi_samples
    ;;
  markdown)
    markdown_samples
    ;;
  html)
    html_samples
    ;;
  labels)
    label_samples
    ;;
  all)
    ansi_samples
    markdown_samples
    html_samples
    label_samples
    ;;
  *)
    echo "Unsupported --mode value: $mode" >&2
    exit 2
    ;;
esac
