---
name: macos-disk-cleanup
description: Identify large disk usage on macOS, propose a cleanup plan, and perform safe disk cleanup using Trash (not rm) for common heavy locations like ~/Library, Application Support, Developer/Xcode caches, simulator devices, device support, media app downloads (Podcasts/Prime Video), browser caches (Brave), and Claude VM bundles. Use when the user asks to find largest files/folders, reduce disk usage, or clean caches on macOS.
---

# macOS Disk Cleanup

## Overview

Generate a fast disk-usage report, identify the biggest culprits, and carry out targeted cleanup in a safe, reversible way (move to Trash) with clear user confirmation.

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
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Service Worker`
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Cache`
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/Default/Code Cache`
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/Default/GPUCache`
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/ShaderCache`
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/GrShaderCache`
  - `~/Library/Application Support/BraveSoftware/Brave-Browser/component_crx_cache`

## Scripts

- `scripts/scan_disk_usage.sh`: fast usage snapshot for common macOS locations.
- `scripts/cleanup_targets.sh`: curated cleanup with `trash`, supporting flags:
  - `--xcode`, `--claude-vm`, `--podcasts`, `--prime-video`, `--brave-cache`, `--all`
  - `--apply` to perform cleanup (default is dry run)
  - `--quit-apps` to stop related apps first
