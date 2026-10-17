export PATH=$HOME/aospa/prebuilts/clang/host/linux-x86/clang-r547379/bin:$HOME/aospa/prebuilts/build-tools/linux-x86/bin:$PATH
KSRC=$HOME/work/k66/kernel/xiaomi/sm4450
KOUT=$HOME/work/k66/out
EXT_ROOT=$HOME/work/k66/kernel/xiaomi/sm4450-modules
MAKEARGS="ARCH=arm64 LLVM=1 LLVM_IAS=1 CC=clang CROSS_COMPILE=aarch64-linux-gnu- DEPMOD=true CONFIG_XIAOMI_DEVICE_DTBS=y CONFIG_SKY_DTB=y"
