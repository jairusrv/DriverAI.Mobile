package com.driverai.driverai_mobile

import android.content.Context
import org.json.JSONArray

object DriverAiRedZoneDetector {

    data class Point(
        val lat: Double,
        val lng: Double
    )

    data class Zone(
        val id: String,
        val h3Index: String,
        val points: List<Point>
    )

    fun findMatchingZone(
        context: Context,
        lat: Double,
        lng: Double
    ): Zone? {
        val zones = loadZones(context)

        for (zone in zones) {
            if (isPointInsidePolygon(lat, lng, zone.points)) {
                return zone
            }
        }

        return null
    }

    private fun loadZones(
        context: Context
    ): List<Zone> {
        val json =
            DriverAiHexZoneRepository.getZonesJson(context)

        if (json.isBlank() || json == "[]") {
            return emptyList()
        }

        val result = mutableListOf<Zone>()

        try {
            val array = JSONArray(json)

            for (i in 0 until array.length()) {
                val item = array.getJSONObject(i)

                val enabled =
                    item.optBoolean("enabled", true)

                if (!enabled) continue

                val pointsArray =
                    item.optJSONArray("points") ?: continue

                val points = mutableListOf<Point>()

                for (j in 0 until pointsArray.length()) {
                    val point =
                        pointsArray.getJSONObject(j)

                    points.add(
                        Point(
                            lat = point.getDouble("lat"),
                            lng = point.getDouble("lng")
                        )
                    )
                }

                if (points.size >= 3) {
                    result.add(
                        Zone(
                            id = item.optString("id"),
                            h3Index = item.optString("h3Index"),
                            points = points
                        )
                    )
                }
            }
        } catch (_: Exception) {
            return emptyList()
        }

        return result
    }

    private fun isPointInsidePolygon(
        lat: Double,
        lng: Double,
        polygon: List<Point>
    ): Boolean {
        var inside = false
        var j = polygon.size - 1

        for (i in polygon.indices) {
            val pi = polygon[i]
            val pj = polygon[j]

            val intersects =
                ((pi.lng > lng) != (pj.lng > lng)) &&
                    (lat < (pj.lat - pi.lat) * (lng - pi.lng) / (pj.lng - pi.lng) + pi.lat)

            if (intersects) {
                inside = !inside
            }

            j = i
        }

        return inside
    }
}