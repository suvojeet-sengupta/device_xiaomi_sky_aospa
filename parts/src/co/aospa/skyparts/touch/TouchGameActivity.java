/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package co.aospa.skyparts.touch;

import android.os.Bundle;
import android.view.MenuItem;

import com.android.settingslib.collapsingtoolbar.CollapsingToolbarBaseActivity;

public class TouchGameActivity extends CollapsingToolbarBaseActivity {

    private static final String TAG_TOUCH_GAME = "touch_game";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        getFragmentManager().beginTransaction().replace(
                com.android.settingslib.collapsingtoolbar.R.id.content_frame,
                new TouchGameSettingsFragment(),
                TAG_TOUCH_GAME
        ).commit();
    }

    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        if (item.getItemId() == android.R.id.home) {
            onBackPressed();
            return true;
        }
        return super.onOptionsItemSelected(item);
    }
}
