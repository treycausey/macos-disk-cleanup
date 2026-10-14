#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME}"

disk_usage() {
  du "$@" 2>/dev/null || printf 'Note: du reported unreadable paths; usage may be incomplete.\n' >&2
}

printf "=== Filesystem (Data volume) ===\n"
df -h /System/Volumes/Data

printf "\n=== Top-level home usage (largest 20) ===\n"
disk_usage -sh "$ROOT"/* | sort -h | tail -n 20

printf "\n=== ~/Library top-level (largest 20) ===\n"
disk_usage -h -d 1 "$ROOT/Library" | sort -h | tail -n 20

printf "\n=== ~/Library/Application Support top-level (largest 30) ===\n"
disk_usage -h -d 1 "$ROOT/Library/Application Support" | sort -h | tail -n 30

printf "\n=== ~/Library/Developer top-level (largest 20) ===\n"
disk_usage -h -d 1 "$ROOT/Library/Developer" | sort -h | tail -n 20

printf "\n=== Large files (>1G) in common folders ===\n"
find "$ROOT/Downloads" "$ROOT/Documents" "$ROOT/Movies" "$ROOT/Pictures" "$ROOT/dev" \
  -type f -size +1G -print 2>/dev/null || true
