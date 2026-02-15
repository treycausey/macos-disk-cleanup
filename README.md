# macos-disk-cleanup

`macos-disk-cleanup` is a skill for identifying large disk usage on macOS and cleaning known heavy targets using a controlled, script-driven workflow.

## DANGER

This skill can remove important local data.

Using `--apply` moves selected paths to Trash, including development artifacts and app-managed files such as:
- Xcode simulator/device data
- Cached or downloaded media data
- Browser cache and service worker data
- Claude VM bundles

If you choose the wrong targets, you can lose data you still need.

Do not run cleanup until you have reviewed the exact target paths and confirmed the impact.

## What This Skill Is For

Use this skill when you want to:
- Find what is taking space in your home directory and `~/Library`
- Generate a cleanup plan based on large directories/files
- Remove selected high-impact caches or temporary data in a safer way (Trash instead of direct delete)

## Included Scripts

- `scripts/scan_disk_usage.sh`
  - Produces a quick storage report (`df`, large directories, and large files)
- `scripts/cleanup_targets.sh`
  - Supports dry run and apply mode for curated cleanup categories

## Safe Workflow (Required)

1. Run a baseline scan:
   ```bash
   scripts/scan_disk_usage.sh
   ```
2. Choose cleanup categories conservatively.
3. Run cleanup in dry-run mode first:
   ```bash
   scripts/cleanup_targets.sh --xcode --podcasts
   ```
4. Review every listed target path.
5. Only then run with `--apply`:
   ```bash
   scripts/cleanup_targets.sh --xcode --podcasts --apply
   ```
6. Re-check free space:
   ```bash
   df -h /System/Volumes/Data
   ```
7. Empty Trash manually only after final verification.

## Cleanup Flags

- `--xcode`
- `--claude-vm`
- `--podcasts`
- `--prime-video`
- `--brave-cache`
- `--all`
- `--apply`
- `--quit-apps`

## Additional Cautions

- Close related apps before cleanup for consistent results.
- `--quit-apps` forcibly stops matching apps.
- Do not treat cached data as disposable unless you understand what will be regenerated and what may be lost.
- Keep backups for anything you cannot afford to lose.
