#!/usr/bin/env bash
set -euo pipefail
shopt -s nullglob

usage() {
  cat <<'USAGE'
Usage: cleanup_targets.sh [options]

Target categories:
  --xcode           Remove Xcode caches, simulators, and device support data
  --claude-vm       Remove Claude app VM bundles
  --podcasts        Remove Podcasts temp/cache downloads
  --prime-video     Remove Prime Video offline downloads
  --brave-cache     Remove Brave cache/service worker data
  --all             Select all categories above

Execution controls:
  --apply           Perform the cleanup (default is dry run)
  --quit-apps       Attempt to quit related apps before cleanup
  --help            Show this help

Examples:
  cleanup_targets.sh --xcode --podcasts
  cleanup_targets.sh --all --apply --quit-apps
USAGE
}

APPLY=false
QUIT_APPS=false

SELECT_XCODE=false
SELECT_CLAUDE=false
SELECT_PODCASTS=false
SELECT_PRIME=false
SELECT_BRAVE=false

if [[ $# -eq 0 ]]; then
  usage
  exit 1
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --xcode) SELECT_XCODE=true ;;
    --claude-vm) SELECT_CLAUDE=true ;;
    --podcasts) SELECT_PODCASTS=true ;;
    --prime-video) SELECT_PRIME=true ;;
    --brave-cache) SELECT_BRAVE=true ;;
    --all)
      SELECT_XCODE=true
      SELECT_CLAUDE=true
      SELECT_PODCASTS=true
      SELECT_PRIME=true
      SELECT_BRAVE=true
      ;;
    --apply) APPLY=true ;;
    --quit-apps) QUIT_APPS=true ;;
    --help) usage; exit 0 ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
  shift
 done

if ! $SELECT_XCODE && ! $SELECT_CLAUDE && ! $SELECT_PODCASTS && ! $SELECT_PRIME && ! $SELECT_BRAVE; then
  echo "No cleanup targets selected." >&2
  usage
  exit 1
fi

if $QUIT_APPS; then
  pkill -x "Xcode" || true
  pkill -x "Simulator" || true
  pkill -x "Podcasts" || true
  pkill -x "Brave Browser" || true
  pkill -x "Claude" || true
  pkill -x "Prime Video" || true
fi

if ! command -v trash >/dev/null 2>&1; then
  echo "Missing required command: trash" >&2
  echo "Install trash or adapt the script to your deletion policy." >&2
  exit 1
fi

TARGETS=()

add_if_exists() {
  local path="$1"
  if [[ -e "$path" ]]; then
    TARGETS+=("$path")
  fi
}

if $SELECT_XCODE; then
  add_if_exists "$HOME/Library/Developer/XCTestDevices"
  add_if_exists "$HOME/Library/Developer/CoreSimulator/Devices"
  add_if_exists "$HOME/Library/Developer/Xcode/iOS DeviceSupport"
  add_if_exists "$HOME/Library/Developer/Xcode/UserData/Previews"
  add_if_exists "$HOME/Library/Developer/Xcode/DerivedData"
fi

if $SELECT_CLAUDE; then
  add_if_exists "$HOME/Library/Application Support/Claude/vm_bundles"
fi

if $SELECT_PODCASTS; then
  add_if_exists "$HOME/Library/Containers/com.apple.podcasts/Data/tmp"
  add_if_exists "$HOME/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library/Cache"
fi

if $SELECT_PRIME; then
  for path in "$HOME/Library/Containers/com.amazon.aiv.AIVApp/Data/Library/com.apple.UserManagedAssets"*; do
    add_if_exists "$path"
  done
fi

if $SELECT_BRAVE; then
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Service Worker"
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cache"
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/Code Cache"
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/GPUCache"
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/Default/ShaderCache"
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/GrShaderCache"
  add_if_exists "$HOME/Library/Application Support/BraveSoftware/Brave-Browser/component_crx_cache"
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "No matching paths found for the selected targets." >&2
  exit 1
fi

printf "Targets to move to Trash:\n"
for path in "${TARGETS[@]}"; do
  printf -- "- %s\n" "$path"
done

if ! $APPLY; then
  printf "\nDry run only. Re-run with --apply to perform cleanup.\n"
  exit 0
fi

trash -rf -- "${TARGETS[@]}"

printf "\nCleanup complete. Empty Trash to reclaim disk space.\n"
