#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d "$REPO_ROOT/tests/scan-fixture.XXXXXX")"
cleanup() {
  chmod 700 "$FIXTURE/home/Library/unreadable"
  rm -rf "$FIXTURE"
}
trap cleanup EXIT

mkdir -p "$FIXTURE/bin" "$FIXTURE/home/Library/unreadable" \
  "$FIXTURE/home/Library/Application Support" "$FIXTURE/home/Library/Developer" \
  "$FIXTURE/home/Downloads" "$FIXTURE/home/Documents" "$FIXTURE/home/Movies" \
  "$FIXTURE/home/Pictures" "$FIXTURE/home/dev"
printf 'fixture data\n' > "$FIXTURE/home/Library/unreadable/file"
# The Data volume is macOS-specific and irrelevant to this regression.
printf '#!/usr/bin/env bash\nprintf "Filesystem fixture\\n"\n' > "$FIXTURE/bin/df"
chmod +x "$FIXTURE/bin/df"
chmod 000 "$FIXTURE/home/Library/unreadable"

if du -sh "$FIXTURE/home/Library" > "$FIXTURE/du-output" 2>&1; then
  printf 'FAIL: fixture did not produce a du read error\n' >&2
  exit 1
fi
printf 'PASS: real du reports an unreadable directory\n'

status=0
PATH="$FIXTURE/bin:$PATH" bash "$REPO_ROOT/scripts/scan_disk_usage.sh" "$FIXTURE/home" \
  > "$FIXTURE/output" 2>&1 || status=$?
if [ "$status" -ne 0 ]; then
  cat "$FIXTURE/output"
  printf 'FAIL: scan exited %s after a du read error\n' "$status" >&2
  exit 1
fi
# These are literal report headings, including the tilde.
# shellcheck disable=SC2088
for heading in 'Top-level home usage' '~/Library top-level' \
  '~/Library/Application Support top-level' '~/Library/Developer top-level' \
  'Large files (>1G)'; do
  if ! grep -Fq "$heading" "$FIXTURE/output"; then
    printf 'FAIL: missing section %s\n' "$heading" >&2
    exit 1
  fi
done
if ! grep -Fq 'Note: du reported unreadable paths' "$FIXTURE/output"; then
  printf 'FAIL: missing unreadable-path note\n' >&2
  exit 1
fi
if ! grep -Fq "$FIXTURE/home/Library" "$FIXTURE/output"; then
  printf 'FAIL: partial du results were lost\n' >&2
  exit 1
fi
printf 'PASS: scan completes all sections, retains partial usage, and reports unreadable paths\n'

chmod 700 "$FIXTURE/home/Library/unreadable"
PATH="$FIXTURE/bin:$PATH" bash "$REPO_ROOT/scripts/scan_disk_usage.sh" "$FIXTURE/home" \
  > "$FIXTURE/readable-output" 2>&1
if grep -Fq 'Note: du reported unreadable paths' "$FIXTURE/readable-output"; then
  printf 'FAIL: readable scan reported unreadable paths\n' >&2
  exit 1
fi
printf 'PASS: readable scan completes without an unreadable-path note\n'
