# OTA updates

Unofficial sky builds update through ParanoidHub (Settings > System >
System update) like official ones. `SkyParanoidHubOverlay` points it at
[`sky.json`](sky.json) here on the `calcite-6.6` branch, and the
`UnofficialOta` feature patch shows the maintainer on the update screen.

ParanoidHub offers a build when its `build_type` matches the phone's
`ro.aospa.build.variant` (`unofficial`) and its `datetime` is newer than the
running build. A/B installs go through update_engine, so the full signed zip
is all a release needs.

## Releasing a build

1. Build with `./rom-build.sh sky`, then write the feed from the root of the
   tree, so the build props in out/ belong to the zip:

   ```bash
   device/xiaomi/sky/ota/make-feed.sh aospa-calcite-unofficial-sky-<date>.zip [url]
   ```

   Use the flashable zip, not the fastboot `-image.zip`. Put the changes in `ota/changelog.txt` before running it;
   it goes into the feed as the changelog ParanoidHub shows.
2. Upload the zip as an asset of a `sky-<date>` release of this repo.
   GitHub takes assets up to 2 GiB; for a bigger zip, host it elsewhere and
   pass its direct download url as the second argument of `make-feed.sh`.
3. Commit `ota/sky.json` and push `calcite-6.6`. Phones see the build on their
   next check, or when you tap "Check for update".

To pull a broken build, revert that commit. A feed with an empty `updates`
list offers nothing.

## Feed format

[`example.json`](example.json) is a filled-in feed for one build.
`make-feed.sh` writes the same thing from a real zip. Every value is a
string.

| Field | What it is |
| --- | --- |
| `android_spl` | Security patch of the build, passed to the system as the pending update's patch level (the update screen shows the running build's) |
| `build_type` | Must match the phone's `ro.aospa.build.variant` (`unofficial`) or the build isn't offered |
| `changelog_device` | Shown under the build name; `\n` for new lines |
| `datetime` | Build time in seconds (`ro.build.date.utc`); only builds newer than the running one are offered |
| `filename` | Name of the zip as it's saved on the phone |
| `maintainer` | Shown as "Maintainer: ..." on the update screen |
| `recovery_sha256` | SHA-256 of the zip; the download is checked against it |
| `size` | Size of the zip in bytes |
| `url` | Direct download link to the zip |
| `version`, `version_code` | Shown with `build_type` as the build name, e.g. "Calcite unofficial 20261023" |

With several entries, ParanoidHub offers the newest matching one.
