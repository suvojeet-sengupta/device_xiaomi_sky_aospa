/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package co.aospa.skyparts.touch;

import android.os.SystemProperties;

import co.aospa.skyparts.R;

public final class TouchGameUtils {

    static final String MODE_AUTO = "auto";
    static final String MODE_ON = "on";
    static final String MODE_OFF = "off";

    private static final String PROP_MODE = "persist.sys.sky.touch_game_mode";

    private TouchGameUtils() {}

    static String getMode() {
        String mode = SystemProperties.get(PROP_MODE, MODE_AUTO);
        return MODE_ON.equals(mode) || MODE_OFF.equals(mode) ? mode : MODE_AUTO;
    }

    static void setMode(String mode) {
        SystemProperties.set(PROP_MODE, mode);
    }

    static String nextMode(String mode) {
        switch (mode) {
            case MODE_AUTO:
                return MODE_ON;
            case MODE_ON:
                return MODE_OFF;
            default:
                return MODE_AUTO;
        }
    }

    static int getModeLabel(String mode) {
        switch (mode) {
            case MODE_ON:
                return R.string.touch_game_on;
            case MODE_OFF:
                return R.string.touch_game_off;
            default:
                return R.string.touch_game_auto;
        }
    }
}
