---
name: macos-disk-cleanup
description: Identify large disk usage on macOS, propose a cleanup plan, and perform safe disk cleanup using Trash (not rm) for common heavy locations like ~/Library, Application Support, Developer/Xcode caches, simulator devices, device support, media app downloads (Podcasts/Prime Video), browser caches (Brave), and Claude VM bundles. Use when the user asks to find largest files/folders, reduce disk usage, or clean caches on macOS.
---

# macOS Disk Cleanup

## Overview

Generate a fast disk-usage report, identify the biggest culprits, and carry out targeted cleanup in a safe, reversible way (move to Trash) with clear user confirmation.

## Never relocate app data with a symlink

Do not move an app's data folder to another volume and leave a symlink in its place. This applies to Messages, Photos, Mail, and anything under `~/Library/Containers`, `~/Library/Group Containers`, or `~/Library/Messages`. Sandboxed apps cannot read or write through a symlink to `/Volumes`. They fail without a visible error: the kernel log shows `Sandbox: … deny(1) file-write-create /Volumes/…`, and the app shows blank placeholders. On 2026-09-27, a cleanup session moved `~/Library/Messages/Attachments` (49 GB) to an external drive this way. No Messages attachment downloaded for 9 days.

To free space from app data, use the app's own setting instead: Messages "Keep messages" or Messages in iCloud, Photos "Optimize Mac Storage", or the app's library-location setting. Before you move any folder off the boot volume, ask the user and name the app that owns it.

## Quick Start

1. Run `scripts/scan_disk_usage.sh` to gather a summary.
2. Summarize largest directories and propose a cleanup plan.
3. Execute cleanup with `scripts/cleanup_targets.sh ... --apply` after user confirmation.
4. Re-check space with `df -h /System/Volumes/Data` and remind to empty Trash.

## Workflow

1. **Baseline scan**
   - `scripts/scan_disk_usage.sh`
   - Note the top-level `~/Library` sections, plus any large files outside Library.

2. **Plan + confirm**
   - Call out high-impact targets and any app/data impact.
   - Ask for confirmation before cleanup; do not empty Trash unless explicitly requested.

3. **Prepare**
   - Quit related apps if requested (`--quit-apps` flag).

4. **Clean up**
   - Use `scripts/cleanup_targets.sh` with the selected flags and `--apply`.

5. **Verify + wrap up**
   - Re-run `df -h /System/Volumes/Data`.
   - Note Trash size and remind to empty Trash to reclaim space.

## Targets Cheat Sheet (Common Safe Wins)

- **Xcode + Simulators**
  - `~/Library/Developer/XCTestDevices`
  - `~/Library/Developer/CoreSimulator/Devices`
  - `~/Library/Developer/Xcode/iOS DeviceSupport`
  - `~/Library/Developer/Xcode/UserData/Previews`
  - `~/Library/Developer/Xcode/DerivedData`
- **Claude**
  - `~/Library/Application Support/Claude/vm_bundles`
- **Podcasts**
  - `~/Library/Containers/com.apple.podcasts/Data/tmp`
  - `~/Library/Group Containers/243LU875E5.groups.com.apple.podcasts/Library/Cache`
- **Prime Video**
  - `~/Library/Containers/com.amazon.aiv.AIVApp/Data/Library/com.apple.UserManagedAssets*`
- **Brave (cache only)**
  - Paths are discovered at run time, not hardcoded, because Brave's layout differs
    between versions and installs.
  - Roots searched: `~/Library/Application Support/BraveSoftware/Brave-Browser` and
    `~/Library/Caches/BraveSoftware/Brave-Browser` (each only if present), at the
    browser root and in every profile (`Default` and any `Profile N`).
  - Cache directory names matched: `Cache`, `Code Cache`, `GPUCache`, `ShaderCache`,
    `GrShaderCache`, `DawnGraphiteCache`, `DawnWebGPUCache`, `GraphiteDawnCache`,
    `component_crx_cache`, `extensions_crx_cache`, `Service Worker/CacheStorage`.
  - Never selected: `Local Storage`, `Session Storage`, `IndexedDB`, `Cookies`,
    `History`, `Extensions`, `Local Extension Settings`, `Extension State`,
    `WebStorage`, `blob_storage`. Those are user data, not cache.
  - If nothing matches, the script names the roots it searched on stderr instead of
    reporting success.
- **uv cache (manual, not scripted)**
  - `uv cache clean` blocks on the cache `.lock` held by any long-running `uv run`
    service (for example a launchd `uv run uvicorn`) and waits about 300s; use
    `uv cache clean --force` to skip the in-use check.

## Scripts

- `scripts/scan_disk_usage.sh`: fast usage snapshot for common macOS locations.
- `scripts/cleanup_targets.sh`: curated cleanup with `trash`, supporting flags:
  - `--xcode`, `--claude-vm`, `--podcasts`, `--prime-video`, `--brave-cache`, `--all`
  - `--apply` to perform cleanup (default is dry run)
  - `--quit-apps` to stop related apps first
