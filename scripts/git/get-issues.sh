#!/bin/sh
set -eu

script_dir() {
  case "$0" in
    */*) dirname "$0" ;;
    *) pwd ;;
  esac
}

exec "$(script_dir)/gh-get-issues.sh" "$@"
