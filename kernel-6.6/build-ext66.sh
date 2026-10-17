#!/bin/bash
. ~/work/k66/env.sh
MODS_OUT=$HOME/work/k66/modules-install
KREL=$(cat $KOUT/include/config/kernel.release)
RPATH=$(python3 -c 'import os,sys;print(os.path.relpath(*sys.argv[1:]))' $EXT_ROOT $KSRC)
mkdir -p ~/work/k66/ext-logs
rm -rf $MODS_OUT
make -C $KSRC O=$KOUT $MAKEARGS INSTALL_MOD_PATH=$MODS_OUT INSTALL_MOD_STRIP=1 modules_install > ~/work/k66/ext-logs/00-intree.log 2>&1 || { echo "FAIL intree install"; exit 1; }
i=0; SYMS=
for m in xiaomi  qcom/opensource/mmrm-driver  qcom/opensource/mm-drivers/msm_ext_display  qcom/opensource/mm-drivers/sync_fence  qcom/opensource/audio-kernel  qcom/opensource/securemsm-kernel  qcom/opensource/synx-kernel  qcom/opensource/camera-kernel  qcom/opensource/data-kernel/drivers/smem-mailbox  qcom/opensource/datarmnet-ext/mem  qcom/opensource/dataipa/drivers/platform/msm  qcom/opensource/datarmnet/core  qcom/opensource/datarmnet-ext/aps  qcom/opensource/datarmnet-ext/offload  qcom/opensource/datarmnet-ext/perf  qcom/opensource/datarmnet-ext/perf_tether  qcom/opensource/datarmnet-ext/sch  qcom/opensource/datarmnet-ext/shs  qcom/opensource/datarmnet-ext/wlan  qcom/opensource/display-drivers/msm  qcom/opensource/dsp-kernel  qcom/opensource/graphics-kernel  qcom/opensource/spu-kernel  qcom/opensource/video-driver  qcom/opensource/wlan/platform  qcom/opensource/wlan/qcacld-3.0/.adrastea  qcom/opensource/bt-kernel  nxp/opensource/driver ; do
    i=$((i+1)); log=~/work/k66/ext-logs/$(printf %02d $i)-$(echo $m | tr / _).log
    echo "== $m"
    make -j96 -C $EXT_ROOT/$m M=$RPATH/$m KERNEL_SRC=$KSRC OUT_DIR=$KOUT O=$KOUT $MAKEARGS ${SYMS:+KBUILD_EXTRA_SYMBOLS="$SYMS"} > $log 2>&1 &&
    make -C $EXT_ROOT/$m M=$RPATH/$m KERNEL_SRC=$KSRC OUT_DIR=$KOUT O=$KOUT $MAKEARGS INSTALL_MOD_PATH=$MODS_OUT INSTALL_MOD_STRIP=1 KERNEL_UAPI_HEADERS_DIR=$KOUT modules_install >> $log 2>&1 ||
    { echo "FAIL $m (see $log)"; grep -m8 -E "error|Error|undefined" $log; exit 1; }
    [ -f $EXT_ROOT/$m/Module.symvers ] && SYMS="${SYMS:+$SYMS }$EXT_ROOT/$m/Module.symvers"
done
echo "ALL OK: $(find $MODS_OUT/lib/modules/$KREL -name '*.ko' | wc -l) modules"
