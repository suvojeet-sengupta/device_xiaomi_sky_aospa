# AOSPA calcite setup for sky

Files that live outside the device, vendor and kernel repos.

## vendor_aospa_products_sky
Copy into `vendor/aospa/products/sky/` of an AOSPA calcite tree.
- `beans-5.10.xml` / `beans-6.6.xml`: copy the one you want to `beans.xml`, then run lunch or barista. The 6.6 one uses the LineageOS sm8450-6.6 display and audio HALs instead of the AOSPA 8450 ones. Both include MIUI Camera.
- `aospa_sky.mk`: uses the calcite DeviceProduct/SystemName overrides.

## kernel-6.6
How the `calcite-6.6` prebuilt of device_xiaomi_sky-kernel is made.

The kernel is the xiaomi-ravelin sm4450 kernel, modules and devicetrees
(lineage-24.0), built by a LineageOS tree for sky so that the module sets and
load lists are exactly what that build installs.

1. From the LineageOS build, copy `kernel` to `Image`, `dtb.img` to
   `dtbs/sky.dtb`, `dtbo.img` to `dtbs/`, and `System.map` and
   `Module.symvers` from `obj/KERNEL_OBJ`.
2. Copy every module of `vendor_ramdisk`, `vendor_dlkm` and `system_dlkm`
   (`lib/modules`) into the folder of the same name, with its `modules.load`
   (and `modules.load.recovery` for the ramdisk) written as `name.ko` lines,
   plus `modules.blocklist` and `system_dlkm.modules.blocklist`.
3. `ramoops_dtb.py dtbs/sky.dtb <out>`: split the ramoops region of every dtb
   into 1 MiB console and 1 MiB pmsg, so a failed boot keeps its kernel log.
4. `modcheck.py <prebuilt dir>`: checks vermagic, symbols, modversion CRCs and
   dependencies of every module for first stage, recovery, second stage and
   on-demand loading.

The DT wires the partitions up itself (`TARGET_USES_KERNEL_PLATFORM := false`)
because the QTI kernel platform makefile only installs vendor_dlkm modules that
are in modules.load.

## publish.sh
Copy into the root of the AOSPA tree. After `./rom-build.sh sky -z`, run `./publish.sh` to put the newest build into the ServerHive web folder and print its download links: the recovery zip, the fastboot (`-image.zip`) zip, and boot, vendor_boot and dtbo from its signed target files, each with a `.sha256`. It finds which ServerHive host serves the folder itself (`PUBLISH_URL` overrides that).

- `./publish.sh recovery`, `fastboot` or `images` publishes one kind.
- `./publish.sh list` only prints the links of the newest published files.
- `--keep N` deletes all but the N newest published builds of each kind.
- `--dry-run` only shows what would be published.
