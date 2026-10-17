def edit(p, pairs):
    s = open(p).read()
    for a, b in pairs:
        assert s.count(a) == 1, (p, a[:60]); s = s.replace(a, b)
    open(p, "w").write(s)

edit("BoardConfig.mk", [
    ("    system_ext \\\n    vbmeta \\\n", "    system_dlkm \\\n    system_ext \\\n    vbmeta \\\n"),
    ("    androidboot.memcg=1 \\\n    androidboot.usbcontroller=a600000.dwc3\n",
     "    androidboot.load_modules_parallel=true \\\n    androidboot.memcg=1 \\\n    androidboot.usbcontroller=a600000.dwc3\n"),
    ("BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_ext vendor vendor_dlkm\n",
     "BOARD_QTI_DYNAMIC_PARTITIONS_PARTITION_LIST := odm product system system_dlkm system_ext vendor vendor_dlkm\n"),
    ("    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))\n",
     "    $(eval TARGET_COPY_OUT_$(p) := $(call to-lower, $(p))))\n\n"
     "$(foreach p, SYSTEM_DLKM VENDOR_DLKM, \\\n"
     "    $(eval BOARD_$(p)IMAGE_FILE_SYSTEM_TYPE := erofs) \\\n"
     "    $(eval BOARD_$(p)IMAGE_PARTITION_RESERVED_SIZE :=))\n\n"
     "BOARD_SYSTEM_KERNEL_MODULES := $(wildcard device/xiaomi/sky-kernel/gki_dlkm/*.ko)\n"
     "BOARD_SYSTEM_KERNEL_MODULES_LOAD := $(strip $(shell cat device/xiaomi/sky-kernel/gki_dlkm/modules.load))\n"
     "BOARD_SYSTEM_KERNEL_MODULES_BLOCKLIST_FILE := device/xiaomi/sky-kernel/vendor_dlkm/system_dlkm.modules.blocklist\n"),
    ("$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/qcom-battery/charging_enabled)\n"
     "$(call soong_config_set,lineage_health,charging_control_charging_enabled,1)\n"
     "$(call soong_config_set,lineage_health,charging_control_charging_disabled,0)\n",
     "$(call soong_config_set,lineage_health,charging_control_charging_path,/sys/class/qcom-battery/input_suspend)\n"
     "$(call soong_config_set,lineage_health,charging_control_charging_enabled,0)\n"
     "$(call soong_config_set,lineage_health,charging_control_charging_disabled,1)\n"),
])

p = "rootdir/etc/fstab.qcom"; s = open(p).read()
old = [l for l in s.split("\n") if l.startswith("vendor_dlkm ")][0]
new = (old + "\n" + old.replace("ext4    ro,barrier=1,discard", "erofs   ro                  ")
       + "\n" + old.replace("vendor_dlkm      ", "system_dlkm      ").replace("/vendor_dlkm", "/system_dlkm")
       + "\n" + old.replace("vendor_dlkm      ", "system_dlkm      ").replace("/vendor_dlkm", "/system_dlkm").replace("ext4    ro,barrier=1,discard", "erofs   ro                  "))
assert s.count(old) == 1; open(p, "w").write(s.replace(old, new))

p = "rootdir/etc/init.sky.rc"; s = open(p).read()
a = "    chown system system /sys/class/qcom-battery/charging_enabled\n    chmod 0660 /sys/class/qcom-battery/charging_enabled\n"
assert a in s; open(p, "w").write(s.replace(a, ""))
