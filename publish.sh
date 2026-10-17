#!/bin/bash
# Publish the latest AOSPA sky build zips to the ServerHive web folder and print download links.
# Usage: ./publish.sh [all|fastboot|recovery] [--keep N] [--dry-run]
#   all       fastboot (-image.zip) and recovery (.zip) builds, the default
#   --keep N  keep only the N newest published zips of each kind, older ones are deleted
#   --dry-run show what would be published without copying anything
set -euo pipefail

WEB=/var/www/html/suvojeetsengupta
URL=https://ferrari.serverhive.in/suvojeetsengupta
SRC=$(cd "$(dirname "$0")" && pwd)

what=all keep=0 dry=0
while [ $# -gt 0 ]; do
    case $1 in
        all|fastboot|recovery) what=$1 ;;
        --keep) keep=${2:?--keep needs a number}; shift ;;
        --dry-run|-n) dry=1 ;;
        -h|--help) sed -n 2,6p "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

latest() {
    ls -t "$SRC"/aospa-*.zip 2>/dev/null | if [ "$1" = fastboot ]; then grep -- '-image\.zip$'; else grep -v -- '-image\.zip$'; fi | head -1 || true
}

publish() {
    local kind=$1 f
    f=$(latest "$kind")
    if [ -z "$f" ]; then
        echo "[$kind] no zip found in $SRC" >&2
        return 1
    fi

    if [ -f "$SRC/out/error.log" ] && [ -s "$SRC/out/error.log" ] && [ "$SRC/out/error.log" -nt "$f" ]; then
        echo "[$kind] warning: the last build failed after this zip was made, publishing the older zip" >&2
    fi

    local base stamp suffix name
    base=$(basename "$f" .zip)
    suffix=""
    [ "$kind" = fastboot ] && suffix="-image" && base=${base%-image}
    stamp=$(date -r "$f" +%Y%m%d-%H%M)
    name="${base%-*}-$stamp$suffix.zip"

    echo "[$kind] $(basename "$f") ($(du -h "$f" | cut -f1), built $(date -r "$f" '+%d %b %H:%M'))"
    if [ "$dry" = 1 ]; then
        echo "[$kind] would publish as $URL/$name"
        return 0
    fi

    if [ -f "$WEB/$name" ] && [ "$(stat -c %s "$WEB/$name")" = "$(stat -c %s "$f")" ]; then
        echo "[$kind] already published"
    else
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
        ls -t "$WEB"/"${base%-*}"-????????-????"$suffix".zip 2>/dev/null | tail -n +"$((keep + 1))" | while read -r old; do
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
