# Device Tree for Xiaomi Redmi Note 12R/Redmi 12 5G/POCO M6 Pro 5G (Sky | Skyin)[](https://github.com/sm4450-development/device_xiaomi_sky/README.md#spec-sheet)

## Spec Sheet

| Feature | Specification |
| :--- | :--- |
| CPU | Octa-core<br>2X Cortex A78@ 2.2GHz<br>6X Cortex A55@ 2.0GHz |
| Chipset | Qualcomm® Snapdragon™ 4 Gen 2 Mobile Platform<br>(*Samsung* Foundry's *FinFET*  *4nm*) |
| GPU | Qualcomm® Adreno™ 613 |
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

### What is what

`calcite-6.6` (6.6 kernel) is the main branch and the default on GitHub. `calcite` (5.10 kernel) is kept but not worked on much.

| Repo | Branch | What it has |
|---|---|---|
| [device_xiaomi_sky_aospa](https://github.com/suvojeet-sengupta/device_xiaomi_sky_aospa) (this one) | `calcite-6.6` (6.6 kernel, default), `calcite` (5.10 kernel) | Device tree: configs, overlays, sepolicy and source patches |
| [device_xiaomi_sky-kernel](https://github.com/suvojeet-sengupta/device_xiaomi_sky-kernel) | same as above | Prebuilt kernel and modules |
| [vendor_xiaomi_sky_aospa](https://github.com/suvojeet-sengupta/vendor_xiaomi_sky_aospa) | same as above | Blobs from stock |
| this repo | [`aospa-setup`](https://github.com/suvojeet-sengupta/device_xiaomi_sky_aospa/tree/aospa-setup) | Files that go into the AOSPA tree: `aospa_sky.mk`, the beans (list of repos to sync) and `publish.sh` |

`patches/` holds the changes to AOSPA source: fixes in `patches/aospa/`, extras like App Lock or advanced reboot in `patches/features/<name>/`. You never apply them by hand, they go in by themselves every time `build/envsetup.sh` is sourced. A patch that is already in is skipped.

### Set up the server (once)

1. Get AOSPA:
```bash
mkdir ~/aospa && cd ~/aospa
```
```bash
repo init -u https://github.com/AOSPA/manifest -b calcite
```
```bash
repo sync -c -j$(nproc --all) --force-sync --no-clone-bundle --no-tags
```

2. Add sky to it. `beans-6.6.xml` gets the 6.6 trees; use `beans-5.10.xml` instead for 5.10:
```bash
git clone -b aospa-setup https://github.com/suvojeet-sengupta/device_xiaomi_sky_aospa.git ~/sky-setup
```
```bash
mkdir -p vendor/aospa/products/sky
```
```bash
cp ~/sky-setup/vendor_aospa_products_sky/aospa_sky.mk vendor/aospa/products/sky/
```
```bash
cp ~/sky-setup/vendor_aospa_products_sky/beans-6.6.xml vendor/aospa/products/sky/beans.xml
```

3. Pull the device, kernel and vendor repos:
```bash
python3 vendor/aospa/build/tools/barista.py aospa_sky
```

### Build

```bash
cd ~/aospa && ./rom-build.sh sky -z
```

- The zips land in `out/target/product/sky/`: one for recovery and, with `-z`, an `-image.zip` for fastboot.
- `-t eng` makes an eng build (default is userdebug).
- `-i` cleans the old images first. Use it once after switching kernel or build type.

Got a link-sharing web folder on the server? `cp ~/sky-setup/publish.sh . && ./publish.sh` copies the newest zips there and prints the links.

### Update later

Run barista again to pull the latest device repos, then build. To switch kernel, copy the other `beans-*.xml` over `vendor/aospa/products/sky/beans.xml`, run barista, and build once with `-i`.

### Flash

- **Recovery zip:** in AOSPA recovery, Apply update, then sideload it over ADB or pick it from the SD card.
- **Image zip:** flash it from fastboot.

`boot`, `vendor_boot` and `dtbo` hold the kernel, its modules and the device tree, so they always have to come from the same build. Never flash just one of them from another build.
