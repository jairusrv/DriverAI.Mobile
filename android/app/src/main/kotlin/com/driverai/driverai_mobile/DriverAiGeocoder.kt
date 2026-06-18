package com.driverai.driverai_mobile

import android.content.Context
import android.location.Geocoder
import java.util.Locale

object DriverAiGeocoder {

    data class LocationResult(
        val lat: Double,
        val lng: Double
    )

    fun geocode(
        context: Context,
        address: String
    ): LocationResult? {

        return try {

            val geocoder =
                Geocoder(
                    context,
                    Locale("es", "CR")
                )

            val results =
                geocoder.getFromLocationName(
                    address,
                    1
                )

            if (results.isNullOrEmpty()) {
                null
            } else {
                LocationResult(
                    lat = results[0].latitude,
                    lng = results[0].longitude
                )
            }

        } catch (_: Exception) {
            null
        }
    }
}