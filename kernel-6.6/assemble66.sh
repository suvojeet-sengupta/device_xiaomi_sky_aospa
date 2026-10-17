#!/bin/bash
set -e
. ~/work/k66/env.sh
W=$HOME/work/k66
KREL=$(cat $KOUT/include/config/kernel.release)
MODDIR=$W/modules-install/lib/modules/$KREL
P=$W/sky-kernel-6.6
M=$EXT_ROOT/qcom/opensource

rm -rf $P && mkdir -p $P/dtbs $P/vendor_ramdisk $P/vendor_dlkm $P/system_dlkm
cp $HOME/aospa/device/xiaomi/sky-kernel/Android.bp $P/
cp $KOUT/arch/arm64/boot/Image $KOUT/System.map $KOUT/Module.symvers $P/

cp $W/dtbs-out/*.dtb $P/dtbs/
python3 $HOME/aospa/system/libufdt/utils/src/mkdtboimg.py create $P/dtbs/dtbo.img --page_size=4096 $(ls $W/dtbs-out/*.dtbo | sort)

H=$P/kernel-headers
cp -r $KOUT/usr/include $H
find $H -name ".*" -delete
cp $M/graphics-kernel/include/uapi/linux/*.h $H/linux/
mkdir -p $H/media $H/camera
cp -r $M/video-driver/include/uapi/vidc/media/. $H/media/
cp -r $M/camera-kernel/include/uapi/camera/. $H/camera/
cp -r $M/camera-kernel/include/uapi/camera/media/. $H/media/

clean_list() { grep -v '^\s*#' "$1" | sed 's/\s*$//' | grep -v '^$'; }
sky_vendor="fpc1020_platform_tee.ko fts_8720.ko gf_spi.ko ir-spi.ko nvt_36672c.ko nxp-nci.ko xiaomi_touch.ko"
sky_boot="fts_8720.ko nvt_36672c.ko xiaomi_touch.ko"
first=$(clean_list $W/modules.load.vendorboot)
recovery="$(clean_list $W/modules.load.recovery) $sky_boot"
vendor="$(clean_list $W/modules.load) $sky_vendor"
system=$(clean_list $W/modules.load.system_dlkm)

find_ko() { local f; f=$(find $MODDIR -name "$1" | head -1); [ -n "$f" ] || { echo "MISSING $1" >&2; return 1; }; echo $f; }
missing=0
for m in $first $recovery; do f=$(find_ko $m) && cp $f $P/vendor_ramdisk/ || missing=$((missing+1)); done
for m in $vendor; do f=$(find_ko $m) && cp $f $P/vendor_dlkm/ || missing=$((missing+1)); done
for m in $system; do f=$(find_ko $m) && cp $f $P/system_dlkm/ || missing=$((missing+1)); done

printf '%s\n' $first | awk '!s[$0]++' > $P/vendor_ramdisk/modules.load
printf '%s\n' $first $recovery | awk '!s[$0]++' > $P/vendor_ramdisk/modules.load.recovery
printf '%s\n' $vendor | awk '!s[$0]++' > $P/vendor_dlkm/modules.load
printf '%s\n' $system | awk '!s[$0]++' > $P/system_dlkm/modules.load
cp $KSRC/modules.vendor_blocklist.msm.parrot $P/vendor_ramdisk/modules.blocklist
cp $KSRC/modules.vendor_blocklist.msm.parrot $P/vendor_dlkm/modules.blocklist
cp $KSRC/modules.systemdlkm_blocklist.msm.parrot $P/vendor_dlkm/system_dlkm.modules.blocklist

echo "kernel $KREL"
for d in vendor_ramdisk vendor_dlkm system_dlkm; do echo "$d: $(ls $P/$d/*.ko | wc -l) ko, load=$(wc -l < $P/$d/modules.load)"; done
echo "recovery load=$(wc -l < $P/vendor_ramdisk/modules.load.recovery)"
echo "dtbs: $(ls $P/dtbs)"; echo "headers: $(find $H -name '*.h' | wc -l)"
echo "missing: $missing"
