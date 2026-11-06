/*
 * Copyright (C) 2026 Paranoid Android
 *
 * SPDX-License-Identifier: Apache-2.0
 */

#include <aidl/android/hardware/power/BnPower.h>
#include <android-base/file.h>
#include <android-base/logging.h>
#include <android-base/unique_fd.h>
#include <fcntl.h>
#include <sys/ioctl.h>

namespace aidl {
namespace android {
namespace hardware {
namespace power {
namespace impl {

using ::android::base::unique_fd;
using ::android::base::WriteStringToFile;

static constexpr char kTouchDevice[] = "/dev/xiaomi-touch";
static constexpr char kTopAppUclampMin[] = "/dev/cpuctl/top-app/cpu.uclamp.min";
static constexpr int kTouchSetCurValue = 0;
static constexpr int kTouchGameMode = 0;
static constexpr int kTouchValueSize = 6;
static constexpr char kGameUclampMin[] = "20";

static void setTouchGameMode(bool enabled) {
    unique_fd fd(open(kTouchDevice, O_RDWR | O_CLOEXEC));
    if (fd < 0) {
        PLOG(ERROR) << "Failed to open " << kTouchDevice;
        return;
    }

    int buf[kTouchValueSize] = {kTouchGameMode, enabled ? 1 : 0};
    if (ioctl(fd, _IO('T', kTouchSetCurValue), buf) < 0)
        PLOG(ERROR) << "Failed to set touch game mode to " << enabled;
}

static void setGameBoost(bool enabled) {
    if (!WriteStringToFile(enabled ? kGameUclampMin : "0", kTopAppUclampMin))
        PLOG(ERROR) << "Failed to write " << kTopAppUclampMin;
}

bool isDeviceSpecificModeSupported(Mode type, bool* _aidl_return) {
    switch (type) {
        case Mode::GAME:
            *_aidl_return = true;
            return true;
        default:
            return false;
    }
}

bool setDeviceSpecificMode(Mode type, bool enabled) {
    switch (type) {
        case Mode::GAME:
            setTouchGameMode(enabled);
            setGameBoost(enabled);
            return true;
        default:
            return false;
    }
}

}  // namespace impl
}  // namespace power
}  // namespace hardware
}  // namespace android
}  // namespace aidl
