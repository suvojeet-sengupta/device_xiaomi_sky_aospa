#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import blob_fixup, blob_fixups_user_type
from extract_utils.fixups_lib import (
    lib_fixup_remove,
    lib_fixups as base_lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import ExtractUtils, ExtractUtilsModule

namespace_imports = [
    'device/xiaomi/sky',
    'hardware/xiaomi',
    'vendor/qcom/common/vendor/adreno/s',
    'vendor/qcom/common/vendor/display',
    'vendor/qcom/common/vendor/display/5.10',
    'vendor/qcom/common/vendor/media/5.10',
    'vendor/qcom/common/vendor/perf',
    'vendor/qcom/common/vendor/wlan',
]


def lib_fixup_device_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_sky' if partition == 'vendor' else None


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


def lib_fixup_prebuilt_suffix(lib: str, *args, **kwargs):
    return f'{lib}_prebuilt'


lib_fixups: lib_fixups_user_type = {
    **base_lib_fixups,
    (
        'audio.primary.parrot',
    ): lib_fixup_device_suffix,
    (
        'android.hardware.soundtrigger*',
        'vendor.display.color*',
        'vendor.display.postproc@1.0',
        'vendor.qti.qspmhal@1.0',
        'com.fingerprints.extension*',
        'com.qualcomm.qti.dpm.api@1.0',
        'com.qualcomm.qti.imscmservice*',
        'com.qualcomm.qti.uceservice*',
        'vendor.qti.data.*',
        'vendor.qti.diaghal@1.0',
        'vendor.qti.hardware.ListenSoundModel@1.0',
        'vendor.qti.hardware.camera.postproc@1.0',
        'vendor.qti.hardware.data.*',
        'vendor.qti.hardware.dpmservice*',
        'vendor.qti.hardware.embmssl*',
        'vendor.qti.hardware.limits*',
        'vendor.qti.hardware.mwqemadapter@1.0',
        'vendor.qti.hardware.pal@1.0',
        'vendor.qti.hardware.qccsyshal*',
        'vendor.qti.hardware.qccvndhal@1.0',
        'vendor.qti.hardware.qxr-V1-ndk_platform',
        'vendor.qti.hardware.radio.*',
        'vendor.qti.hardware.slmadapter@1.0',
        'vendor.qti.hardware.wifidisplaysession@1.0',
        'vendor.qti.imsrtpservice@3.0',
        'vendor.qti.ims.*',
        'vendor.qti.latency*',
        'vendor.xiaomi.hardware.displayfeature@1.0',
        'vendor.xiaomi.hardware.mlipay*',
        'vendor.xiaomi.hardware.mtdservice@1.0',
    ): lib_fixup_vendor_suffix,
    'libgrpc++_unsecure': lib_fixup_prebuilt_suffix,
    'libwpa_client': lib_fixup_remove,
}

blob_fixups: blob_fixups_user_type = {
    (
        'vendor/bin/hw/android.hardware.security.keymint-service-qti',
        'vendor/lib64/libqtikeymint.so',
    ): blob_fixup()
        .add_needed('android.hardware.security.rkp-V3-ndk.so'),
    'vendor/lib64/libcamximageformatutils.so': blob_fixup()
        .replace_needed('vendor.qti.hardware.display.config-V2-ndk_platform.so', 'vendor.qti.hardware.display.config-V2-ndk.so'),
    'vendor/lib64/libhme.so': blob_fixup()
        .replace_needed('libstdc++.so', 'libstdc++_vendor.so'),
    'vendor/bin/qcc-trd': blob_fixup()
        .replace_needed('libgrpc++_unsecure.so', 'libgrpc++_unsecure_prebuilt.so'),
    'vendor/lib64/vendor.libdpmframework.so': blob_fixup()
        .add_needed('libhidlbase_shim.so'),
}  # fmt: skip

module = ExtractUtilsModule(
    'sky',
    'xiaomi',
    blob_fixups=blob_fixups,
    lib_fixups=lib_fixups,
    namespace_imports=namespace_imports,
)

if __name__ == '__main__':
    utils = ExtractUtils.device(module)
    utils.run()
