# AOSPA calcite setup for sky

Files that live outside the device, vendor and kernel repos.

## vendor_aospa_products_sky
Copy into `vendor/aospa/products/sky/` of an AOSPA calcite tree.
- `beans-5.10.xml` / `beans-6.6.xml`: copy the one you want to `beans.xml`, then run lunch or barista. The 6.6 one uses the LineageOS sm8450-6.6 display and audio HALs instead of the AOSPA 8450 ones.
- `aospa_sky.mk`: uses the calcite DeviceProduct/SystemName overrides.

## kernel-6.6
How the `calcite-6.6` prebuilt of device_xiaomi_sky-kernel was made.

Layout: forks of xiaomi-ravelin cloned into `~/work/k66/kernel/xiaomi/{sm4450,sm4450-modules,sm4450-devicetrees}` (lineage-24.0).

1. `. env.sh`, then `gki_defconfig` + `merge_config.sh vendor/parrot_perf.config`, disable `UAPI_HEADER_TEST`, `make Image modules dtbs`.
2. `build-ext66.sh`: external modules, in ravelin's order, passing each module's Module.symvers on.
3. dtbs: move `vendor/*/*.dtb{,o}` to a base dir and run `merge_dtbs.py --base <base> --techpack <dts vendor copy> --out <out>`.
   Needs fdtget, fdtput, fdtoverlay, fdtoverlaymerge from LineageOS android_external_dtc (gcc, with `version_gen.h` from tools-src) and ufdt_apply_overlay from system/libufdt.
4. `assemble66.sh`: Image, dtbs, dtbo.img, kernel-headers, module dirs from ravelin's module lists.
5. `curate_headers.py`: keep only vendor UAPI headers, plus 5.10-only ones.
6. `closure.py`: add every module dependency to each load list.

## publish.sh
Copy into the root of the AOSPA tree. After `./rom-build.sh sky -z`, run `./publish.sh` to copy the newest fastboot (`-image.zip`) and recovery zips into the ServerHive web folder and print their download links. `./publish.sh fastboot` or `./publish.sh recovery` publishes one kind, `--keep N` deletes all but the N newest published zips of each kind, and `--dry-run` only shows what would be published.
