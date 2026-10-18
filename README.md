# Device Tree for Xiaomi Redmi Note 12R/Redmi 12 5G/POCO M6 Pro 5G (Sky | Skyin)[](https://github.com/sm4450-development/device_xiaomi_sky/README.md#spec-sheet)

## Spec Sheet

| Feature | Specification |
| :--- | :--- |
| CPU | Octa-core<br>2X Cortex A78@ 2.2GHz<br>6X Cortex A55@ 2.0GHz |
| Chipset | Qualcomm® Snapdragon™ 4 Gen 2 Mobile Platform<br>(*Samsung* Foundry's *FinFET*  *4nm*) |
| GPU | Qualcomm® Adreno™ 619 |
| Memory | 4GB \| 6GB \| 8GB \| (LPDDR4x) |
| Shipped Android Version | 13.0 |
| Storage | 128GB \| 256GB UFS 2.2 |
| Battery | 5000mAh (typ) Li Polymer |
| Dimensions | 168.60mm x 76.28mmx 8.17mm (Weight: 199g) |
| Display | 1080P IPS LCD (6.79" FHD+ Display \| Refresh rate: 90Hz Touch sampling Rate: 240Hz Peak Brightness: 550 nits) |
| Rear Camera | 50 MP, f/1.8, (wide), PDAF<br>2 MP, f/2.4, (depth) |
| Front Camera | 8 MP, f/2.0, (wide), 1.12µm |
| Release Date | 2023, August 01 (Global) |

## Device Picture (Redmi 12 5G)

![Redmi15_5G](https://github.com/prateekmaru/device_xiaomi_sky/assets/47496067/7dac6202-af1d-4942-944a-a8bd167ecf3e)

## Building AOSPA calcite

This tree builds [AOSPA](https://github.com/AOSPA) calcite for sky.

### Branches

| Kernel | Device tree | Kernel prebuilt | Vendor blobs |
|---|---|---|---|
| 5.10 | `calcite` | [device_xiaomi_sky-kernel](https://github.com/suvojeet-sengupta/device_xiaomi_sky-kernel) `calcite` | [vendor_xiaomi_sky_aospa](https://github.com/suvojeet-sengupta/vendor_xiaomi_sky_aospa) `calcite` |
| 6.6 | `calcite-6.6` | [device_xiaomi_sky-kernel](https://github.com/suvojeet-sengupta/device_xiaomi_sky-kernel) `calcite-6.6` | [vendor_xiaomi_sky_aospa](https://github.com/suvojeet-sengupta/vendor_xiaomi_sky_aospa) `calcite-6.6` |

Both also pull in MIUI Camera ([device](https://github.com/suvojeet-sengupta/device_xiaomi_miuicamera-sky) and [vendor](https://github.com/suvojeet-sengupta/vendor_xiaomi_miuicamera-sky), `calcite`).

The files that live outside these repos (AOSPA product makefile, beans, publish script) are on the [`aospa-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_sky_aospa/tree/aospa-setup) branch of this repo.

### Setting up a build tree

#### 1. Sync AOSPA

```bash
mkdir aospa && cd aospa
```
```bash
repo init -u https://github.com/AOSPA/manifest -b calcite
```
```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

#### 2. Add the sky product to AOSPA

```bash
git clone -b aospa-setup https://github.com/suvojeet-sengupta/device_xiaomi_sky_aospa.git ~/sky-setup
```
```bash
mkdir -p vendor/aospa/products/sky
```
```bash
cp ~/sky-setup/vendor_aospa_products_sky/aospa_sky.mk vendor/aospa/products/sky/
```

Pick the kernel. For 5.10:
```bash
cp ~/sky-setup/vendor_aospa_products_sky/beans-5.10.xml vendor/aospa/products/sky/beans.xml
```
Or for 6.6:
```bash
cp ~/sky-setup/vendor_aospa_products_sky/beans-6.6.xml vendor/aospa/products/sky/beans.xml
```

#### 3. Sync the device repos

`beans.xml` lists the device, kernel, vendor, MIUI Camera and HAL repos. Barista turns it into a local manifest and syncs them:
```bash
python3 vendor/aospa/build/tools/barista.py aospa_sky
```

#### 4. Build

```bash
./rom-build.sh sky -z
```

- `-z` also makes a fastboot flashable `-image.zip` next to the recovery zip.
- `-t eng` builds an eng build instead of userdebug.
- `-i` (installclean) is needed for the first build after switching between 5.10 and 6.6, or between userdebug and eng.

The zips end up in `out/target/product/sky/`.

#### 5. Share the build (optional)

```bash
cp ~/sky-setup/publish.sh .
```
```bash
./publish.sh
```
It copies the newest fastboot and recovery zips to the web folder and prints their download links. `./publish.sh --help` lists the options.

### What happens on `source build/envsetup.sh`

`vendorsetup.sh` runs automatically and:
- applies the source patches in `patches/aospa/` and then each feature in `patches/features/<name>/aospa/`, skipping ones that are already applied, and prints any patch that fails;
- merges the split MIUI Camera apk in `vendor/xiaomi/miuicamera-sky`.

Patches carried by this tree:
- healthd: find chargers on every update (charging status)
- Settings: show the maintainer in About phone
- QTI common and power: perf and power HAL tuning
- App Lock
- Hide app list, ignore secure windows, pure black theme, three finger screenshot
- PropImitationHooks without Play Integrity spoofing
- MIUI Camera framework support

### Switching between 5.10 and 6.6

1. Copy the other `beans-*.xml` over `vendor/aospa/products/sky/beans.xml` (step 2).
2. Run barista again (step 3).
3. Build with `-i` once (step 4).

### Flashing

The kernel, its modules and the devicetree overlay come from three partitions that must always match: `boot`, `vendor_boot` and `dtbo`. Never flash only one of them from another build.

- **Recovery zip:** sideload it from AOSPA recovery (Apply update from ADB).
- **Fastboot zip:** flash it from the bootloader. Flash `boot`, `vendor_boot`, `dtbo` and both `vbmeta` images to both slots, then the super partitions from fastbootd.

The recovery image carries no kernel. It uses the kernel from `boot` and the modules from `vendor_boot`, so it runs on whichever kernel the phone has.

### Debugging a boot that fails

The 6.6 kernel keeps the previous boot's kernel log and logcat in ramoops. After a failed boot, reboot into a recovery with a shell and read:
```bash
cat /sys/fs/pstore/console-ramoops-0
```
```bash
cat /sys/fs/pstore/pmsg-ramoops-0
```
