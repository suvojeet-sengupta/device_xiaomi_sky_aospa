#!/bin/bash
#
# SPDX-FileCopyrightText: Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#
# Write the ParanoidHub feed for a signed sky build:
#   device/xiaomi/sky/ota/make-feed.sh <rom.zip> [url]
#
# Run it from the root of the AOSPA tree right after the build, so the
# build props in out/ belong to the zip. Without a url the zip is expected
# as an asset of the sky-<date> release of the device tree on GitHub.
# The changelog comes from changelog.txt next to this script, if there is
# one. The feed is written to <device>.json next to this script; commit and
# push it to publish the build (see README.md).

set -euo pipefail

die() { echo "make-feed: $*" >&2; exit 1; }

zip=${1:-}
[ -f "$zip" ] || die "usage: $0 <rom.zip> [url]"
here=$(cd "$(dirname "$0")" && pwd)
prop=out/target/product/sky/system/build.prop
[ -f "$prop" ] || die "no $prop, run this from the tree you built in"

# The maintainer is in product.prop, so look past the system props too.
getprop() {
    sed -n "s/^$1=//p" "$prop" out/target/product/sky/{product,system_ext}/etc/build.prop \
        2>/dev/null | tail -n 1
}
meta() { unzip -p "$zip" META-INF/com/android/metadata | sed -n "s/^$1=//p"; }

device=$(getprop ro.aospa.device)
timestamp=$(meta post-timestamp)
[ -n "$device" ] && [ -n "$timestamp" ] || die "can't read the device or the build time"
[ "$timestamp" = "$(getprop ro.build.date.utc)" ] ||
    die "$zip isn't the build in out/ (the build times differ)"

major=$(getprop ro.aospa.version.major)
minor=$(getprop ro.aospa.version.minor)
date=$(date -u -d "@$timestamp" +%Y%m%d)
size=$(stat -c %s "$zip")
name=$(basename "$zip")
url=${2:-https://github.com/suvojeet-sengupta/device_xiaomi_sky_aospa/releases/download/$device-$date/$name}

if [ -z "${2:-}" ] && [ "$size" -ge $((2 * 1024 * 1024 * 1024)) ]; then
    die "$name is over 2 GiB, too big for a GitHub release; pass a url"
fi

FEED_SPL=$(meta post-security-patch-level) \
FEED_TYPE=$(getprop ro.aospa.build.variant) \
FEED_TIME=$timestamp \
FEED_NAME=$name \
FEED_MAINTAINER=$(getprop ro.aospa.maintainer) \
FEED_SHA256=$(sha256sum "$zip" | cut -d " " -f 1) \
FEED_SIZE=$size \
FEED_URL=$url \
FEED_VERSION=${major^} \
FEED_CODE=${minor:-$date} \
FEED_CHANGELOG=$here/changelog.txt \
python3 - "$here/$device.json" <<'PY'
import json, os, sys

e = os.environ
try:
    with open(e["FEED_CHANGELOG"]) as f:
        changelog = f.read().strip()
except FileNotFoundError:
    changelog = ""

entry = {
    "android_spl": e["FEED_SPL"],
    "build_type": e["FEED_TYPE"],
    "changelog_device": changelog,
    "datetime": e["FEED_TIME"],
    "filename": e["FEED_NAME"],
    "maintainer": e["FEED_MAINTAINER"],
    "recovery_sha256": e["FEED_SHA256"],
    "size": e["FEED_SIZE"],
    "url": e["FEED_URL"],
    "version": e["FEED_VERSION"],
    "version_code": e["FEED_CODE"],
}
with open(sys.argv[1], "w") as f:
    json.dump({"updates": [entry]}, f, indent=2)
    f.write("\n")
PY

echo "Feed:   $here/$device.json"
echo "Upload: $name to $url"
