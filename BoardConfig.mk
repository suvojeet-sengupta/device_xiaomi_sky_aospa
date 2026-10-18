DEVICE_PATH := device/xiaomi/sky

TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_VARIANT := cortex-a76

# A/B
AB_OTA_UPDATER := true
AB_OTA_PARTITIONS += \
    boot \
    dtbo \
    odm \
    product \
    recovery \
    system \
    system_dlkm \
    system_ext \
    vbmeta \
    vbmeta_system \
    vendor \
    vendor_boot \
    vendor_dlkm

# Bootloader
TARGET_BOARD_INFO_FILE := $(DEVICE_PATH)/board-info.txt
TARGET_BOOTLOADER_BOARD_NAME := sky

# Init
TARGET_INIT_VENDOR_LIB := //$(DEVICE_PATH):libinit_sky
TARGET_RECOVERY_DEVICE_MODULES := libinit_sky

# Build
BUILD_BROKEN_DUP_RULES := true
BUILD_BROKEN_ELF_PREBUILT_PRODUCT_COPY_FILES  := true
BUILD_BROKEN_VENDOR_PROPERTY_NAMESPACE := true

# HIDL
DEVICE_FRAMEWORK_COMPATIBILITY_MATRIX_FILE += $(DEVICE_PATH)/configs/hidl/device_framework_compatibility_matrix.xml
DEVICE_MANIFEST_FILE += $(DEVICE_PATH)/configs/hidl/manifest.xml
ODM_MANIFEST_SKUS += river
ODM_MANIFEST_RIVER_FILES := $(DEVICE_PATH)/configs/hidl/manifest_nfc.xml

# Kernel
BOARD_KERNEL_BASE := 0x00000000
BOARD_KERNEL_PAGESIZE := 4096
BOARD_INCLUDE_DTB_IN_BOOTIMG := true
BOARD_RAMDISK_USE_LZ4 := true
BOARD_USES_GENERIC_KERNEL_IMAGE := true
TARGET_HAS_GENERIC_KERNEL_HEADERS := true

KERNEL_PATH := $(DEVICE_PATH)-kernel
TARGET_PREBUILT_KERNEL := $(KERNEL_PATH)/Image
TARGET_BOARD_KERNEL_HEADERS := $(KERNEL_PATH)/kernel-headers
BOARD_PREBUILT_DTBIMAGE_DIR := $(KERNEL_PATH)/dtbs
BOARD_PREBUILT_DTBOIMAGE := $(KERNEL_PATH)/dtbs/dtbo.img

BOARD_VENDOR_RAMDISK_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/vendor_ramdisk/*.ko)
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_ramdisk/modules.load))
BOARD_VENDOR_RAMDISK_RECOVERY_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_ramdisk/modules.load.recovery))
BOARD_VENDOR_RAMDISK_KERNEL_MODULES_BLOCKLIST_FILE := $(KERNEL_PATH)/vendor_ramdisk/modules.blocklist

BOARD_VENDOR_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/vendor_dlkm/*.ko)
BOARD_VENDOR_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/vendor_dlkm/modules.load))
BOARD_VENDOR_KERNEL_MODULES_BLOCKLIST_FILE := $(KERNEL_PATH)/vendor_dlkm/modules.blocklist

BOARD_SYSTEM_KERNEL_MODULES := $(wildcard $(KERNEL_PATH)/system_dlkm/*.ko)
BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat $(KERNEL_PATH)/system_dlkm/modules.load))

BOARD_BOOT_HEADER_VERSION := 4
BOARD_MKBOOTIMG_ARGS := --header_version $(BOARD_BOOT_HEADER_VERSION)

BOARD_BOOTCONFIG := \
    androidboot.hardware=qcom \
    androidboot.load_modules_parallel=true \
    androidboot.memcg=1 \
    androidboot.serialconsole=0 \
    androidboot.usbcontroller=a600000.dwc3

# Lineage Health
$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/qcom-battery/input_suspend)
$(call soong_config_set,lineage_health,charging_control_charging_enabled,0)
$(call soong_config_set,lineage_health,charging_control_charging_disabled,1)
$(call soong_config_set_bool,lineage_health,charging_control_supports_bypass,false)

# Partitions
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 0x06000000
BOARD_VENDOR_BOOTIMAGE_PARTITION_SIZE := 100663296
BOARD_DTBOIMG_PARTITION_SIZE := 0x1700000
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 0x06400000
BOARD_USES_METADATA_PARTITION := true
BOARD_USES_SYSTEM_DLKMIMAGE := true
BOARD_USES_VENDOR_DLKMIMAGE := true

BOARD_SUPER_PARTITION_SIZE := 6979321856
BOARD_SUPER_PARTITION_GROUPS := qti_dynamic_partitions
BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm
BOARD_QTI_DYNAMIC_PARTITIONS_SIZE := 6975127552 # (BOARD_SUPER_PARTITION_SIZE - 4MB overhead)

$(foreach p, $(call to-upper, $(BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST)), \
    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := ext4) \
    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE := 104857600) \
    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))

$(foreach p, SYSTEM_DLKM VENDOR_DLKM, \
    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE :=))

# RmNet
SOONG_CONFIG_rmnetctl_old_rmnet_data := false

# Power
TARGET_POWER_FEATURE_EXT_LIB := //$(DEVICE_PATH):libpowerfeature_ext_sky

# Recovery
BOARD_EXCLUDE_KERNEL_FROM_RECOVERY_IMAGE := true
BOARD_MOVE_GSI_AVB_KEYS_TO_VENDOR_BOOT := true
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/rootdir/etc/fstab.qcom
TARGET_RECOVERY_PIXEL_FORMAT := RGBX_8888
TARGET_RECOVERY_UI_MARGIN_HEIGHT := 104
TARGET_USERIMAGES_USE_F2FS := true

SOONG_CONFIG_NAMESPACES += ufsbsg
SOONG_CONFIG_ufsbsg += ufsframework
SOONG_CONFIG_ufsbsg_ufsframework := bsg

# Screen density
TARGET_SCREEN_DENSITY := 420

# Security patch level
VENDOR_SECURITY_PATCH := $(PLATFORM_SECURITY_PATCH)

# Sepolicy
TARGET_EXCLUDE_QCOM_SEPOLICY := true
include device/qcom/sepolicy_vndr/SEPolicy.mk
include device/qcom/common/sepolicy/SEPolicy.mk
BOARD_VENDOR_SEPOLICY_DIRS := $(filter-out device/qcom/common/sepolicy/%/vendor/$(TARGET_BOARD_PLATFORM),$(BOARD_VENDOR_SEPOLICY_DIRS))

BOARD_VENDOR_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/vendor
SYSTEM_EXT_PRIVATE_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/private
#SYSTEM_EXT_PUBLIC_SEPOLICY_DIRS += $(DEVICE_PATH)/sepolicy/public

# Verified Boot
BOARD_AVB_ENABLE := true
BOARD_AVB_MAKE_VBMETA_IMAGE_ARGS += --flags 3

BOARD_AVB_RECOVERY_ALGORITHM := SHA256_RSA4096
BOARD_AVB_RECOVERY_KEY_PATH := external/avb/test/data/testkey_rsa4096.pem
BOARD_AVB_RECOVERY_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_RECOVERY_ROLLBACK_INDEX_LOCATION := 1

BOARD_AVB_VBMETA_SYSTEM := system system_ext product
BOARD_AVB_VBMETA_SYSTEM_ALGORITHM := SHA256_RSA2048
BOARD_AVB_VBMETA_SYSTEM_KEY_PATH := external/avb/test/data/testkey_rsa2048.pem
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX := $(PLATFORM_SECURITY_PATCH_TIMESTAMP)
BOARD_AVB_VBMETA_SYSTEM_ROLLBACK_INDEX_LOCATION := 2

# Vendor API
BOARD_SHIPPING_API_LEVEL := 31

# Wi-Fi
CONFIG_ACS := true

# Vibrator
SOONG_CONFIG_NAMESPACES += XIAOMI_VIBRATOR
SOONG_CONFIG_XIAOMI_VIBRATOR := USE_EFFECT_STREAM
SOONG_CONFIG_XIAOMI_VIBRATOR_USE_EFFECT_STREAM := true

# Audio (sm8450-6.6 HAL)
AUDIO_FEATURE_ENABLED_DLKM := true
AUDIO_FEATURE_ENABLED_EXTENDED_COMPRESS_FORMAT := true
AUDIO_FEATURE_ENABLED_GKI := true
AUDIO_FEATURE_ENABLED_INSTANCE_ID := true
AUDIO_FEATURE_ENABLED_MCS := true
AUDIO_FEATURE_ENABLED_SVA_MULTI_STAGE := true
BOARD_SUPPORTS_OPENSOURCE_STHAL := true
BOARD_SUPPORTS_SOUND_TRIGGER := true
BOARD_USES_ALSA_AUDIO := true
TARGET_PROVIDES_AUDIO_HAL := true
TARGET_PROVIDES_LIBAGM := true
TARGET_PROVIDES_LIBAR_PAL := true

$(call soong_config_set,qtiaudio,feature_extended_compress_format,true)
$(call soong_config_set,qtiaudio,feature_gki,true)
$(call soong_config_set,qtiaudio,feature_instance_id,true)
$(call soong_config_set,qtiaudio,feature_mcs,true)
$(call soong_config_set,qtiaudio,feature_sound_trigger,true)
$(call soong_config_set,qtiaudio,feature_sva_multi_stage,true)

# Display (sm8450-6.6 HAL)
SOONG_CONFIG_NAMESPACES += qtidisplay
SOONG_CONFIG_qtidisplay += \
    composer_version drmpp headless llvmsa gralloc4 displayconfig_enabled udfps \
    default master_side_cp shift_horizontal shift_vertical smmu_proxy var1 var2 \
    var3 hwasan hw_fence_disabled hy11 hy22 hy33 llvmcov mapper_ext \
    ubwcp_headers wide_color target_kernel_version target_no_camera_custom_format \
    target_no_raw10_custom_format target_uses_aligned_ycbcr_height \
    target_uses_aligned_ycrcb_height target_uses_unaligned_nv21_zsl \
    target_uses_unaligned_ycrcb target_uses_ycrcb_camera_preview \
    target_uses_ycrcb_venus_camera_preview

SOONG_CONFIG_qtidisplay_composer_version := v3_3
SOONG_CONFIG_qtidisplay_drmpp := true
SOONG_CONFIG_qtidisplay_headless := false
SOONG_CONFIG_qtidisplay_llvmsa := false
SOONG_CONFIG_qtidisplay_gralloc4 := true
SOONG_CONFIG_qtidisplay_displayconfig_enabled := false
SOONG_CONFIG_qtidisplay_udfps := false
SOONG_CONFIG_qtidisplay_default := true
SOONG_CONFIG_qtidisplay_master_side_cp := false
SOONG_CONFIG_qtidisplay_shift_horizontal := 0
SOONG_CONFIG_qtidisplay_shift_vertical := 0
SOONG_CONFIG_qtidisplay_smmu_proxy := false
SOONG_CONFIG_qtidisplay_var1 := false
SOONG_CONFIG_qtidisplay_var2 := false
SOONG_CONFIG_qtidisplay_var3 := false
SOONG_CONFIG_qtidisplay_hwasan := false
SOONG_CONFIG_qtidisplay_hw_fence_disabled := false
SOONG_CONFIG_qtidisplay_hy11 := false
SOONG_CONFIG_qtidisplay_hy22 := false
SOONG_CONFIG_qtidisplay_hy33 := false
SOONG_CONFIG_qtidisplay_llvmcov := false
SOONG_CONFIG_qtidisplay_mapper_ext := true
SOONG_CONFIG_qtidisplay_ubwcp_headers := false
SOONG_CONFIG_qtidisplay_wide_color := false
SOONG_CONFIG_qtidisplay_target_kernel_version := 6.6
SOONG_CONFIG_qtidisplay_target_no_camera_custom_format := false
SOONG_CONFIG_qtidisplay_target_no_raw10_custom_format := false
SOONG_CONFIG_qtidisplay_target_uses_aligned_ycbcr_height := false
SOONG_CONFIG_qtidisplay_target_uses_aligned_ycrcb_height := false
SOONG_CONFIG_qtidisplay_target_uses_unaligned_nv21_zsl := false
SOONG_CONFIG_qtidisplay_target_uses_unaligned_ycrcb := false
SOONG_CONFIG_qtidisplay_target_uses_ycrcb_camera_preview := false
SOONG_CONFIG_qtidisplay_target_uses_ycrcb_venus_camera_preview := false

# Properties
TARGET_PRODUCT_PROP += $(DEVICE_PATH)/configs/props/product.prop
TARGET_SYSTEM_EXT_PROP += $(DEVICE_PATH)/configs/props/system_ext.prop
TARGET_VENDOR_PROP += $(DEVICE_PATH)/configs/props/vendor.prop

# MIUI Camera
-include device/xiaomi/miuicamera-sky/BoardConfig.mk
