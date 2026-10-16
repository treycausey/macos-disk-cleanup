#!/usr/bin/env bash
set -euo pipefail

ROOT="${1:-$HOME}"

disk_usage() {
  du "$@" 2>/dev/null || printf 'Note: du reported unreadable paths; usage may be incomplete.\n' >&2
}

# Network and VM mounts are skipped. ~/OrbStack is OrbStack's NFS view of its
# Linux machines: du through it ran over 10 minutes and reported a phantom
# 317G that is not on this Mac's disk (papercut 2026-09-27). A top-level
# entry is skipped when it is named OrbStack or is the mount point of a
# non-local filesystem (no `local` flag in mount(8): nfs, smbfs, afpfs,
# webdav, autofs). Every du also runs with -x, so a mount nested deeper is
# never crossed. Local volumes mounted in the tree (~/dev on its own APFS
# volume) are still measured: they are real disk use.
nonlocal_mounts() {
  mount | /usr/bin/grep -v -E '[(, ]local[,)]' | sed -n 's/^.* on \(\/.*\) ([^)]*)$/\1/p'
}
NONLOCAL=$(nonlocal_mounts || true)

skip_entry() {
  [ "$(basename "$1")" = "OrbStack" ] && return 0
  [ -n "$NONLOCAL" ] && printf '%s\n' "$NONLOCAL" | /usr/bin/grep -qxF "$1" && return 0
  return 1
}

printf "=== Filesystem (Data volume) ===\n"
df -h /System/Volumes/Data

printf "\n=== Top-level home usage (largest 20) ===\n"
entries=()
skipped=()
for e in "$ROOT"/*; do
  [ -e "$e" ] || [ -L "$e" ] || continue
  if skip_entry "$e"; then skipped+=("$e"); else entries+=("$e"); fi
done
if [ ${#entries[@]} -gt 0 ]; then
  disk_usage -xsh "${entries[@]}" | sort -h | tail -n 20
fi
if [ ${#skipped[@]} -gt 0 ]; then
  printf "(skipped network/VM mounts: %s)\n" "${skipped[*]}"
fi

printf "\n=== ~/Library top-level (largest 20) ===\n"
disk_usage -x -h -d 1 "$ROOT/Library" | sort -h | tail -n 20

printf "\n=== ~/Library/Application Support top-level (largest 30) ===\n"
disk_usage -x -h -d 1 "$ROOT/Library/Application Support" | sort -h | tail -n 30

printf "\n=== ~/Library/Developer top-level (largest 20) ===\n"
disk_usage -x -h -d 1 "$ROOT/Library/Developer" | sort -h | tail -n 20

printf "\n=== Large files (>1G) in common folders ===\n"
find "$ROOT/Downloads" "$ROOT/Documents" "$ROOT/Movies" "$ROOT/Pictures" "$ROOT/dev" \
  -xdev -type f -size +1G -print 2>/dev/null || true
