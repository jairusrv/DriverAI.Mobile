package com.driverai.driverai_mobile

import android.content.Context

object DriverAiHexZoneRepository {

    private const val PREFS_NAME = "driverai_hex_zones"
    private const val KEY_ZONES_JSON = "zones_json"

    fun saveZones(
        context: Context,
        json: String
    ) {
        context
            .getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )
            .edit()
            .putString(
                KEY_ZONES_JSON,
                json
            )
            .apply()
    }

    fun getZonesJson(
        context: Context
    ): String {
        return context
            .getSharedPreferences(
                PREFS_NAME,
                Context.MODE_PRIVATE
            )
            .getString(
                KEY_ZONES_JSON,
                "[]"
            ) ?: "[]"
    }
}