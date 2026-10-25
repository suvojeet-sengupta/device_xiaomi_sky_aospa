#!/vendor/bin/sh
#
# SPDX-FileCopyrightText: Paranoid Android
# SPDX-License-Identifier: Apache-2.0
#

# Pages go into zram with lz4. Every hour, recompress the ones nobody
# touched since the last round with zstd, the secondary algorithm that
# init.kernel.post_boot.sh sets up. Pages that are read get their idle
# mark cleared, so only cold pages pay for zstd.

zram=/sys/block/zram0

[ -f $zram/recompress ] || exit 0
grep -q zstd $zram/recomp_algorithm || exit 0

while true; do
    echo all > $zram/idle
    sleep 3600
    echo type=idle > $zram/recompress
done
