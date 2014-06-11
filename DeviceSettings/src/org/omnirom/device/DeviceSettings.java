/*
 * Copyright (C) 2013 CyanogenMod Project
 * Copyright (C) 2013 The OmniROM Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package org.omnirom.device;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.hardware.TvOut;
import android.os.Bundle;
import android.preference.CheckBoxPreference;
import android.preference.ListPreference;
import android.preference.Preference;
import android.preference.PreferenceActivity;
import android.preference.PreferenceCategory;

public class DeviceSettings extends PreferenceActivity  {

    public static final String KEY_MDNIE = "mdnie";
    public static final String KEY_BACKLIGHT_TIMEOUT = "backlight_timeout";
    public static final String KEY_HSPA = "hspa";
    public static final String KEY_HSPA_CATEGORY = "category_radio";
    public static final String KEY_TVOUT_ENABLE = "tvout_enable";
    public static final String KEY_TVOUT_SYSTEM = "tvout_system";
    public static final String KEY_TVOUT_CATEGORY = "category_tvout";
    public static final String KEY_VOLUME_BOOST = "volume_boost";
    public static final String KEY_VOLUME_CATEGORY = "category_volume_boost";
    public static final String KEY_CARDOCK_AUDIO = "cardock_audio";
    public static final String KEY_DESKDOCK_AUDIO = "deskdock_audio";
    public static final String KEY_DOCK_AUDIO_CATEGORY = "category_dock_audio";

    private ListPreference mMdnie;
    private ListPreference mBacklightTimeout;
    private ListPreference mHspa;
    private CheckBoxPreference mTvOutEnable;
    private ListPreference mTvOutSystem;
    private TvOut mTvOut;
    private VolumeBoostPreference mVolumeBoost;
    private CheckBoxPreference mCarDockAudio;
    private CheckBoxPreference mDeskDockAudio;

    private BroadcastReceiver mHeadsetReceiver = new BroadcastReceiver() {

        @Override
        public void onReceive(Context context, Intent intent) {
            int state = intent.getIntExtra("state", 0);
            updateTvOutEnable(state != 0);
        }

    };

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        addPreferencesFromResource(R.xml.main);

        mMdnie = (ListPreference) findPreference(KEY_MDNIE);
        mMdnie.setEnabled(Mdnie.isSupported());
        mMdnie.setOnPreferenceChangeListener(new Mdnie());

        mBacklightTimeout = (ListPreference) findPreference(KEY_BACKLIGHT_TIMEOUT);
        mBacklightTimeout.setEnabled(TouchKeyBacklightTimeout.isSupported());
        mBacklightTimeout.setOnPreferenceChangeListener(new TouchKeyBacklightTimeout());

        mHspa = (ListPreference) findPreference(KEY_HSPA);
        if (Hspa.isSupported()) {
           mHspa.setOnPreferenceChangeListener(new Hspa(this));
        } else {
           PreferenceCategory category = (PreferenceCategory) getPreferenceScreen().findPreference(KEY_HSPA_CATEGORY);
           category.removePreference(mHspa);
           getPreferenceScreen().removePreference(category);
        }

        mVolumeBoost = (VolumeBoostPreference) findPreference(KEY_VOLUME_BOOST);
        if (!VolumeBoostPreference.isSupported()) {
            PreferenceCategory category = (PreferenceCategory) getPreferenceScreen().findPreference(KEY_VOLUME_CATEGORY);
            category.removePreference(mVolumeBoost);
            getPreferenceScreen().removePreference(category);
        }

        mCarDockAudio = (CheckBoxPreference) findPreference(KEY_CARDOCK_AUDIO);
        mDeskDockAudio = (CheckBoxPreference) findPreference(KEY_DESKDOCK_AUDIO);
        if (DockAudio.isSupported()) {
            mCarDockAudio.setOnPreferenceChangeListener(new DockAudio());
            mDeskDockAudio.setOnPreferenceChangeListener(new DockAudio());
        } else {
            PreferenceCategory category = (PreferenceCategory) getPreferenceScreen().findPreference(KEY_DOCK_AUDIO_CATEGORY);
            category.removePreference(mCarDockAudio);
            category.removePreference(mDeskDockAudio);
            getPreferenceScreen().removePreference(category);
        }

        mTvOut = new TvOut();
        mTvOutEnable = (CheckBoxPreference) findPreference(KEY_TVOUT_ENABLE);
        mTvOutSystem = (ListPreference) findPreference(KEY_TVOUT_SYSTEM);

        if (mTvOut.isSupported()) {

            mTvOutEnable.setChecked(mTvOut._isEnabled());
            mTvOutEnable.setOnPreferenceChangeListener(new Preference.OnPreferenceChangeListener() {

                @Override
                public boolean onPreferenceChange(Preference preference, Object newValue) {
                    boolean enable = (Boolean) newValue;
                    Intent i = new Intent(DeviceSettings.this, TvOutService.class);
                    i.putExtra(TvOutService.EXTRA_COMMAND, enable ? TvOutService.COMMAND_ENABLE : TvOutService.COMMAND_DISABLE);
                    startService(i);
                    return true;
                }

            });

            mTvOutSystem.setOnPreferenceChangeListener(new Preference.OnPreferenceChangeListener() {

                @Override
                public boolean onPreferenceChange(Preference preference, Object newValue) {
                    if (mTvOut._isEnabled()) {
                        int newSystem = Integer.valueOf((String) newValue);
                        Intent i = new Intent(DeviceSettings.this, TvOutService.class);
                        i.putExtra(TvOutService.EXTRA_COMMAND, TvOutService.COMMAND_CHANGE_SYSTEM);
                        i.putExtra(TvOutService.EXTRA_SYSTEM, newSystem);
                        startService(i);
                    }
                    return true;
                }

            });
        } else {
            PreferenceCategory category = (PreferenceCategory) getPreferenceScreen().findPreference(KEY_TVOUT_CATEGORY);
            category.removePreference(mTvOutEnable);
            category.removePreference(mTvOutSystem);
            getPreferenceScreen().removePreference(category);
        }
    }

    @Override
    protected void onResume() {
        super.onResume();
        registerReceiver(mHeadsetReceiver, new IntentFilter(Intent.ACTION_HEADSET_PLUG));
    }

    @Override
    protected void onPause() {
        super.onPause();
        unregisterReceiver(mHeadsetReceiver);
    }

    private void updateTvOutEnable(boolean connected) {
        mTvOutEnable.setEnabled(connected);
        mTvOutEnable.setSummaryOff(connected ? R.string.tvout_enable_summary : R.string.tvout_enable_summary_nocable);

        if (!connected && mTvOutEnable.isChecked()) {
            // Disable on unplug (UI)
            mTvOutEnable.setChecked(false);
        }
    }

    @Override
    protected void onDestroy() {
        mTvOut.finalize();
        super.onDestroy();
    }

}
