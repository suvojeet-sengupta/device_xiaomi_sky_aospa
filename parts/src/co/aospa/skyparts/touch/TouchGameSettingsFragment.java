/*
 * SPDX-FileCopyrightText: 2026 Suvojeet Sengupta
 * SPDX-License-Identifier: Apache-2.0
 */

package co.aospa.skyparts.touch;

import android.os.Bundle;

import androidx.preference.ListPreference;
import androidx.preference.Preference;
import androidx.preference.PreferenceFragment;

import co.aospa.skyparts.R;

public class TouchGameSettingsFragment extends PreferenceFragment
        implements Preference.OnPreferenceChangeListener {

    private static final String KEY_MODE = "touch_game_mode";

    @Override
    public void onCreatePreferences(Bundle savedInstanceState, String rootKey) {
        setPreferencesFromResource(R.xml.touch_game_settings, rootKey);

        ListPreference modePreference = findPreference(KEY_MODE);
        if (modePreference != null) {
            modePreference.setValue(TouchGameUtils.getMode());
            modePreference.setOnPreferenceChangeListener(this);
        }
    }

    @Override
    public boolean onPreferenceChange(Preference preference, Object newValue) {
        TouchGameUtils.setMode((String) newValue);
        TouchGameTileService.updateTile(getActivity());
        return true;
    }
}
