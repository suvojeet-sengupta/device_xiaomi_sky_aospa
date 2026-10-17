#!/usr/bin/env -S PYTHONPATH=../../../tools/extract-utils python3
#
# SPDX-FileCopyrightText: 2024 The LineageOS Project
# SPDX-License-Identifier: Apache-2.0
#

from extract_utils.fixups_blob import blob_fixup, blob_fixups_user_type
from extract_utils.fixups_lib import (
    lib_fixups as base_lib_fixups,
    lib_fixups_user_type,
)
from extract_utils.main import ExtractUtils, ExtractUtilsModule

namespace_imports = [
    'device/xiaomi/sky',
    'hardware/xiaomi',
    'vendor/qcom/common/vendor/wlan',
]


def lib_fixup_vendor_suffix(lib: str, partition: str, *args, **kwargs):
    return f'{lib}_{partition}' if partition == 'vendor' else None


lib_fixups: lib_fixups_user_type = {
    **base_lib_fixups,
    (
        'com.qualcomm.qti.dpm.api@1.0',
        'vendor.qti.ImsRtpService-V1-ndk',
        'vendor.qti.data.factoryservice-V1-ndk',
        'vendor.qti.data.mwqemaidlservice-V1-ndk',
        'vendor.qti.diaghal-V1-ndk',
        'vendor.qti.hardware.cacertaidlservice-V1-ndk',
        'vendor.qti.hardware.data.cneaidlservice.internal.api-V1-ndk',
        'vendor.qti.hardware.data.cneaidlservice.internal.constants-V1-ndk',
        'vendor.qti.hardware.data.cneaidlservice.internal.server-V1-ndk',
        'vendor.qti.hardware.data.connectionfactory-V1-ndk',
        'vendor.qti.hardware.data.dataactivity-V1-ndk',
        'vendor.qti.hardware.data.dynamicddsaidlservice-V1-ndk',
        'vendor.qti.hardware.data.flowaidlservice-V1-ndk',
        'vendor.qti.hardware.data.ka-V1-ndk',
        'vendor.qti.hardware.data.lceaidlservice-V1-ndk',
        'vendor.qti.hardware.data.qmiaidlservice-V1-ndk',
        'vendor.qti.hardware.dpmaidlservice-V1-ndk',
        'vendor.qti.hardware.embmsslaidl-V2-ndk',
        'vendor.qti.hardware.mwqemadapteraidlservice-V1-ndk',
        'vendor.qti.hardware.wifidisplaysession_aidl-V1-ndk',
        'vendor.qti.ims.callcapabilityaidlservice-V1-ndk',
        'vendor.qti.ims.configaidlservice-V1-ndk',
        'vendor.qti.ims.connectionaidlservice-V1-ndk',
        'vendor.qti.ims.factoryaidlservice-V1-ndk',
        'vendor.qti.ims.imscmaidlservice-V1-ndk',
        'vendor.qti.ims.rcssipaidlservice-V1-ndk',
        'vendor.qti.ims.rcsuceaidlservice-V1-ndk',
        'vendor.qti.ims.uceaidlservice-V1-ndk',
        'vendor.qti.latencyaidlservice-V1-ndk',
        'vendor.qti.qccsyshal_aidl-V1-ndk',
        'vendor.qti.qccvndhal_aidl-V1-ndk',
    ): lib_fixup_vendor_suffix,
}

blob_fixups: blob_fixups_user_type = {
    ('system_ext/etc/seccomp_policy/tcmd.policy', 'vendor/etc/seccomp_policy/qsap_qapeservice.policy', 'vendor/etc/seccomp_policy/syshealthmon.policy'): blob_fixup()
        .add_line_if_missing('lseek: 1'),
    (
        'vendor/bin/poweropt-service',
        'vendor/lib64/hw/libaudioeffecthal.qti.so',
        'vendor/lib64/libaodoptfeature.so',
        'vendor/lib64/libaudiocloudctrl.so',
        'vendor/lib64/libcamerapoweroptfeature.so',
        'vendor/lib64/libdpps.so',
        'vendor/lib64/libgamepoweroptfeature.so',
        'vendor/lib64/liblearningmodule.so',
        'vendor/lib64/liboffscreenpoweroptfeature.so',
        'vendor/lib64/libpowercore.so',
        'vendor/lib64/libpsmoptfeature.so',
        'vendor/lib64/libsnapdragoncolor-manager.so',
        'vendor/lib64/libstandbyfeature.so',
        'vendor/lib64/libvideooptfeature.so',
    ): blob_fixup()
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    'system_ext/priv-app/ims/ims.apk': blob_fixup()
        .apktool_patch('blob-patches/ims.patch'),
    'vendor/lib64/libxiaomi_qcril.so': blob_fixup()
        # xiaomi_modem_check_odm_white_list() restarts qcril on devices missing from its ODM whitelist
        .sig_replace('ff 43 01 d1 fd 7b 01 a9 f8 5f 02 a9 f6 57 03 a9 f4 4f 04 a9 fd 43 00 91 00 10 80 52 50 a9 01 94', 'c0 03 5f d6'),
    'vendor/lib64/qcrilNr_aidl_IRadioNetwork.so': blob_fixup()
        # qcril reports NR CA as private RIL technology 30, which utils::convert(RIL_RadioTechnology) doesn't know;
        # map unknown technologies to NR (20) instead of UNKNOWN so the data RAT doesn't drop out during NR CA
        .sig_replace('f2 0a 00 94 e8 03 1f 2a 04 00 00 14', 'f2 0a 00 94 88 02 80 52 04 00 00 14'),
    'vendor/lib64/camx.provider-impl.so': blob_fixup()
        # CameraProvider::getConcurrentCameraIds() fails when the HAL has no concurrent combinations
        .sig_replace('b7 43 5d b8 96 00 80 52 80 3e 00 35', 'b7 43 5d b8 16 00 80 52'),
    'vendor/etc/media_codecs_ravelin.xml': blob_fixup()
        .regex_replace('.*media_codecs_(google_audio|google_c2|google_telephony|google_video|vendor_audio).*\n', ''),
    'vendor/etc/seccomp_policy/gnss@2.0-qsap-location.policy': blob_fixup()
        .add_line_if_missing('sched_get_priority_min: 1')
        .add_line_if_missing('sched_get_priority_max: 1'),
    ('vendor/lib64/libapengine.so', 'vendor/lib64/libqti-perfd.so'): blob_fixup()
        .replace_needed('vendor.qti.hardware.display.config-V5-ndk.so', 'vendor.qti.hardware.display.config-V12-ndk.so')
        .replace_needed('libtinyxml2.so', 'libtinyxml2-v34.so'),
    'vendor/lib64/android.hardware.bluetooth.audio-impl_prebuilt.so': blob_fixup()
        .replace_needed('libbluetooth_audio_session_aidl.so', 'libbluetooth_audio_session_aidl_prebuilt.so'),
    'vendor/lib64/libqcodec2_core.so': blob_fixup()
        .replace_needed('android.hardware.graphics.common-V5-ndk.so', 'android.hardware.graphics.common-V7-ndk.so'),
    'vendor/lib64/libwfdmmsrc_proprietary.so': blob_fixup()
        .replace_needed('android.media.audio.common.types-V2-ndk.so', 'android.media.audio.common.types-V3-ndk.so'),
    'vendor/bin/hw/vendor.qti.hardware.display.allocator@4.0-service': blob_fixup()
        .replace_needed('libgralloccore.so', 'libgralloccore_hidl.so')
        .replace_needed('libgrallocutils.so', 'libgrallocutils_hidl.so'),
    (
        'vendor/lib64/hw/fingerprint.fpc.default.so',
        'vendor/lib64/hw/fingerprint.goodix.default.so',
    ): blob_fixup()
        .fix_soname(),
    'vendor/lib64/hw/camera.qcom.so': blob_fixup()
        .replace_needed('libsnsapi.so', 'libsnsapi_camx.so'),
    'vendor/etc/sensors/hals.conf': blob_fixup()
        .regex_replace(r'sensors\.ssc\.so', 'sensors.ssc_sky.so'),
    'vendor/lib64/sensors.touch.so': blob_fixup()
        .replace_needed('libsnsapi.so', 'libsnsapi_camx.so')
        .replace_needed('libssc.so', 'libssc_sky.so'),
    'vendor/lib64/libcamximageformatutils.so': blob_fixup()
        .replace_needed('vendor.qti.hardware.display.config-V2-ndk_platform.so', 'vendor.qti.hardware.display.config-V5-ndk.so'),
    'vendor/lib64/libgralloccore_hidl.so': blob_fixup()
        .fix_soname()
        .replace_needed('libgrallocutils.so', 'libgrallocutils_hidl.so'),
    'vendor/lib64/libgrallocutils_hidl.so': blob_fixup()
        .fix_soname(),
    'vendor/lib64/libhme.so': blob_fixup()
        .replace_needed('libstdc++.so', 'libstdc++_vendor.so'),
    'vendor/lib64/libsnsapi_camx.so': blob_fixup()
        .fix_soname(),
    (
        'vendor/lib64/libsnsdiaglog_sky.so',
        'vendor/lib64/libssc_sky.so',
        'vendor/lib64/sensors.ssc_sky.so',
    ): blob_fixup()
        .fix_soname()
        .replace_needed('libsnsapi.so', 'libsnsapi_camx.so')
        .replace_needed('libssc.so', 'libssc_sky.so')
        .replace_needed('libsnsdiaglog.so', 'libsnsdiaglog_sky.so'),
    'vendor/lib64/camera/': blob_fixup()
        .clear_symbol_version('remote_register_buf'),
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
