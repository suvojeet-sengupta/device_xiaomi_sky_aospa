#!/bin/bash
# Publish the latest AOSPA sky build to the ServerHive web folder and print download links.
# Usage: ./publish.sh [all|recovery|fastboot|images|list] [--keep N] [--dry-run]
#   all       recovery zip, fastboot zip and boot/vendor_boot/dtbo images, the default
#   list      only print the links of the newest published files of each kind
#   --keep N  keep only the N newest published builds of each kind, older ones are deleted
#   --dry-run show what would be published without copying anything
# Files are published as <name>-<user|userdebug>-<kind>-<build time>IST-<random>, each
# with a .sha256 next to it. The web address is found by asking each ServerHive host for
# a probe file; set PUBLISH_URL to skip that, and PUBLISH_WEB_DIR for another folder.
set -euo pipefail

WEB=${PUBLISH_WEB_DIR:-/var/www/html/$USER}
HOSTS="ferrari unicorn"
SRC=$(cd "$(dirname "$0")" && pwd)
IMAGES="boot vendor_boot dtbo"

what=all keep=0 dry=0
while [ $# -gt 0 ]; do
    case $1 in
        all|recovery|fastboot|images|list) what=$1 ;;
        --keep) keep=${2:?--keep needs a number}; shift ;;
        --dry-run|-n) dry=1 ;;
        -h|--help) sed -n 2,10p "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
    shift
done

[ -d "$WEB" ] || { echo "No web folder at $WEB, set PUBLISH_WEB_DIR" >&2; exit 1; }

# The rental decides which host serves the folder, so find it.
find_url() {
    if [ -n "${PUBLISH_URL:-}" ]; then
        echo "${PUBLISH_URL%/}"
        return
    fi
    local token probe host
    token=$(head -c 8 /dev/urandom | od -An -tx1 | tr -d ' \n')
    probe=".publish-probe-$token"
    echo "$token" > "$WEB/$probe"
    chmod 644 "$WEB/$probe"
    for host in $HOSTS; do
        if [ "$(curl -s -m 10 "https://$host.serverhive.in/$USER/$probe" || true)" = "$token" ]; then
            rm -f "$WEB/$probe"
            echo "https://$host.serverhive.in/$USER"
            return
        fi
    done
    rm -f "$WEB/$probe"
    echo "Couldn't find which host serves $WEB, set PUBLISH_URL" >&2
    exit 1
}
URL=$(find_url)

links=()

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

# Copy a file in under a temporary name, so a download never sees half of it,
# and leave its sha256 next to it.
put() {
    local from=$1 name=$2
    cp "$from" "$WEB/.$name.part"
    chmod 644 "$WEB/.$name.part"
    mv -f "$WEB/.$name.part" "$WEB/$name"
    (cd "$WEB" && sha256sum "$name" > "$name.sha256" && chmod 644 "$name.sha256")
}

# Print the link of a published file and check that the web server has it.
show() {
    local kind=$1 name=$2 code
    code=$(curl -s -o /dev/null -I -w '%{http_code}' "$URL/$name" || true)
    echo "[$kind] HTTP $code, sha256 $(cut -c1-64 "$WEB/$name.sha256" 2>/dev/null || echo "?")"
    echo "[$kind] $URL/$name"
    links+=("$kind: $URL/$name")
}

# The published file of this kind and build, if there is one: same name up to
# the random tag, same size.
already() {
    local prefix=$1 suffix=$2 size=$3 old
    for old in "$WEB/$prefix"-????????"$suffix"; do
        [ -f "$old" ] || continue
        if [ "$(stat -c %s "$old")" = "$size" ]; then
            basename "$old"
            return
        fi
    done
}

prune() {
    local pattern=$1 old
    [ "$keep" -gt 0 ] || return 0
    ls -t "$WEB"/$pattern 2>/dev/null | tail -n +"$((keep + 1))" | while read -r old; do
        rm -f "$old" "$old.sha256" && echo "removed old $(basename "$old")"
    done
}

tag() {
    head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n'
}

publish_zip() {
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

    name=$(already "$prefix" .zip "$(stat -c %s "$f")")
    if [ -n "$name" ]; then
        echo "[$kind] already published"
    else
        name="$prefix-$(tag).zip"
        if [ "$dry" = 1 ]; then
            echo "[$kind] would publish as $URL/$name"
            return 0
        fi
        echo "[$kind] checking the zip..."
        unzip -tq "$f" >/dev/null || { echo "[$kind] $f is corrupt, not publishing" >&2; return 1; }
        echo "[$kind] copying..."
        put "$f" "$name"
    fi

    show "$kind" "$name"
    prune "${base%-*}-*-$kind-????????-????IST-????????.zip"
}

# boot, vendor_boot (which holds recovery) and dtbo of the newest build, from
# its signed target files rather than out/, so they match the zips.
publish_images() {
    local tf base variant stamp when prefix t img name tmp
    tf=$(ls -t "$SRC"/aospa-*-target_files.zip 2>/dev/null | head -1 || true)
    if [ -z "$tf" ]; then
        echo "[images] no target files found in $SRC" >&2
        return 1
    fi
    base=$(basename "$tf" .zip)
    base=${base%-target_files}
    base=${base%-signed}
    rec="$SRC/$base.zip"
    [ -f "$rec" ] || rec=$tf
    read -r variant stamp when < <(build_info "$rec")
    prefix="${base%-*}-$variant-images-${stamp}IST"
    echo "[images] from $(basename "$tf"), built $when"

    tmp=$(mktemp -d)
    unzip -o -j -q "$tf" $(for img in $IMAGES; do echo "IMAGES/$img.img"; done) -d "$tmp" 2>/dev/null || true

    # One tag for the whole set, reused if part of it is already up.
    t=""
    for img in $IMAGES; do
        [ -f "$tmp/$img.img" ] || continue
        name=$(already "$prefix" "-$img.img" "$(stat -c %s "$tmp/$img.img")")
        if [ -n "$name" ]; then
            t=${name#"$prefix-"}
            t=${t%%-*}
            break
        fi
    done
    [ -n "$t" ] || t=$(tag)

    for img in $IMAGES; do
        if [ ! -f "$tmp/$img.img" ]; then
            echo "[images] no $img.img in the target files" >&2
            continue
        fi
        name="$prefix-$t-$img.img"
        if [ -f "$WEB/$name" ] && [ "$(stat -c %s "$WEB/$name")" = "$(stat -c %s "$tmp/$img.img")" ]; then
            :
        elif [ "$dry" = 1 ]; then
            echo "[images] would publish as $URL/$name"
            continue
        else
            put "$tmp/$img.img" "$name"
        fi
        show "$img" "$name"
    done
    rm -rf "$tmp"
    for img in $IMAGES; do
        prune "${base%-*}-*-images-????????-????IST-????????-$img.img"
    done
}

# Links of what is already up, newest of each kind.
list() {
    local kind f found=0
    for kind in recovery fastboot; do
        f=$(ls -t "$WEB"/aospa-*-"$kind"-????????-????IST-????????.zip 2>/dev/null | head -1 || true)
        [ -n "$f" ] || continue
        found=1
        echo "[$kind] $(basename "$f") ($(du -h "$f" | cut -f1))"
        show "$kind" "$(basename "$f")"
    done
    for kind in $IMAGES; do
        f=$(ls -t "$WEB"/aospa-*-images-????????-????IST-????????-"$kind".img 2>/dev/null | head -1 || true)
        [ -n "$f" ] || continue
        found=1
        show "$kind" "$(basename "$f")"
    done
    [ "$found" = 1 ] || echo "Nothing published in $WEB yet"
}

rc=0
case $what in
    all)
        publish_zip recovery || rc=1
        publish_zip fastboot || rc=1
        publish_images || rc=1
        ;;
    recovery|fastboot) publish_zip "$what" || rc=1 ;;
    images) publish_images || rc=1 ;;
    list) list ;;
esac

if [ "$what" != recovery ] && [ -f "$WEB/sky-flash-all.bat" ]; then
    links+=("flash: $URL/sky-flash-all.bat  |  $URL/sky-flash-all.sh")
fi

if [ ${#links[@]} -gt 0 ] && [ "$dry" = 0 ]; then
    echo
    echo "Download links:"
    printf '  %s\n' "${links[@]}"
fi
exit $rc
