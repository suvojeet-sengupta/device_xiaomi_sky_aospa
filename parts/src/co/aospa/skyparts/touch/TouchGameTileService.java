/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package co.aospa.skyparts.touch;

import android.content.ComponentName;
import android.content.Context;
import android.service.quicksettings.Tile;
import android.service.quicksettings.TileService;
import android.util.Log;

public class TouchGameTileService extends TileService {

    private static final String TAG = "TouchGameTile";

    @Override
    public void onStartListening() {
        super.onStartListening();
        updateTileUI();
    }

    @Override
    public void onClick() {
        super.onClick();
        TouchGameUtils.setMode(TouchGameUtils.nextMode(TouchGameUtils.getMode()));
        updateTileUI();
    }

    private void updateTileUI() {
        Tile tile = getQsTile();
        if (tile == null) {
            return;
        }

        String mode = TouchGameUtils.getMode();
        tile.setState(TouchGameUtils.MODE_OFF.equals(mode)
                ? Tile.STATE_INACTIVE : Tile.STATE_ACTIVE);
        tile.setSubtitle(getString(TouchGameUtils.getModeLabel(mode)));
        tile.updateTile();
    }

    static void updateTile(Context context) {
        try {
            requestListeningState(context,
                    new ComponentName(context, TouchGameTileService.class));
        } catch (Exception e) {
            Log.e(TAG, "Failed to refresh tile state", e);
        }
    }
}
