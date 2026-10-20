#!/bin/bash
# Publish the latest AOSPA sky build zips to the ServerHive web folder and print download links.
# Usage: ./publish.sh [all|fastboot|recovery] [--keep N] [--dry-run]
#   all       fastboot (-image.zip) and recovery (.zip) builds, the default
#   --keep N  keep only the N newest published zips of each kind, older ones are deleted
#   --dry-run show what would be published without copying anything
# Zips are published as <name>-<user|userdebug>-<recovery|fastboot>-<build time>IST-<random>.zip
set -euo pipefail

WEB=/var/www/html/suvojeetsengupta
URL=https://unicorn.serverhive.in/suvojeetsengupta
SRC=$(cd "$(dirname "$0")" && pwd)

what=all keep=0 dry=0
while [ $# -gt 0 ]; do
    case $1 in
        all|fastboot|recovery) what=$1 ;;
        --keep) keep=${2:?--keep needs a number}; shift ;;
        --dry-run|-n) dry=1 ;;
        -h|--help) sed -n 2,7p "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

latest() {
    ls -t "$SRC"/aospa-*.zip 2>/dev/null | grep -v -- '-target_files\.zip$' |
        if [ "$1" = fastboot ]; then grep -- '-image\.zip$'; else grep -v -- '-image\.zip$'; fi | head -1 || true
}

# Build type and build time come from the OTA metadata of the recovery zip,
# which the fastboot zip of the same build does not carry.
build_info() {
    local meta ts variant
    meta=$(unzip -p "$1" META-INF/com/android/metadata 2>/dev/null || true)
    ts=$(sed -n 's/^post-timestamp=//p' <<<"$meta")
    variant=$(sed -n 's/^post-build=.*:\([a-z]*\)\/[a-z-]*$/\1/p' <<<"$meta")
    [ -n "$ts" ] || ts=$(date -r "$1" +%s)
    echo "${variant:-unknown} $(TZ=Asia/Kolkata date -d "@$ts" +%Y%m%d-%H%M) $(TZ=Asia/Kolkata date -d "@$ts" '+%d %b %Y, %I:%M %p IST')"
}

publish() {
    local kind=$1 f rec
    f=$(latest "$kind")
    if [ -z "$f" ]; then
        echo "[$kind] no zip found in $SRC" >&2
        return 1
    fi

    if [ -f "$SRC/out/error.log" ] && [ -s "$SRC/out/error.log" ] && [ "$SRC/out/error.log" -nt "$f" ]; then
        echo "[$kind] warning: the last build failed after this zip was made, publishing the older zip" >&2
    fi

    local base variant stamp when prefix name
    base=$(basename "$f" .zip)
    base=${base%-image}
    rec="$SRC/$base.zip"
    [ -f "$rec" ] || rec=$f
    read -r variant stamp when < <(build_info "$rec")
    prefix="${base%-*}-$variant-$kind-${stamp}IST"

    echo "[$kind] $(basename "$f") ($(du -h "$f" | cut -f1), $variant)"
    echo "[$kind] built $when"

    name=""
    for old in "$WEB/$prefix"-*.zip; do
        [ -f "$old" ] || continue
        if [ "$(stat -c %s "$old")" = "$(stat -c %s "$f")" ]; then
            name=$(basename "$old")
            break
        fi
    done

    if [ -n "$name" ]; then
        echo "[$kind] already published"
    else
        name="$prefix-$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n').zip"
        if [ "$dry" = 1 ]; then
            echo "[$kind] would publish as $URL/$name"
            return 0
        fi
        echo "[$kind] checking the zip..."
        unzip -tq "$f" >/dev/null || { echo "[$kind] $f is corrupt, not publishing" >&2; return 1; }
        echo "[$kind] copying..."
        cp "$f" "$WEB/.$name.part"
        chmod 644 "$WEB/.$name.part"
        mv -f "$WEB/.$name.part" "$WEB/$name"
    fi

    local code
    code=$(curl -s -o /dev/null -I -w '%{http_code}' "$URL/$name" || true)
    echo "[$kind] md5 $(md5sum "$WEB/$name" | cut -c1-32), HTTP $code"
    echo "[$kind] $URL/$name"

    if [ "$keep" -gt 0 ]; then
        ls -t "$WEB"/"${base%-*}"-*-"$kind"-????????-????IST-????????.zip 2>/dev/null |
            tail -n +"$((keep + 1))" | while read -r old; do
            rm -f "$old" && echo "[$kind] removed old $(basename "$old")"
        done
    fi
}

rc=0
case $what in
    all) publish fastboot || rc=1; publish recovery || rc=1 ;;
    *) publish "$what" || rc=1 ;;
esac

if [ "$what" != recovery ] && [ -f "$WEB/sky-flash-all.bat" ]; then
    echo "[flash] $URL/sky-flash-all.bat  |  $URL/sky-flash-all.sh"
fi
exit $rc
