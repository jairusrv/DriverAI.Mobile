package com.driverai.driverai_mobile

import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class DriverAiOcrProcessor {

    private var lastText = ""

    private val recognizer = TextRecognition.getClient(
        TextRecognizerOptions.DEFAULT_OPTIONS
    )

    fun process(
        bitmap: Bitmap,
        onOfferDetected: (OfferResult) -> Unit,
        onComplete: () -> Unit
    ) {
        val image = InputImage.fromBitmap(bitmap, 0)

        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val text = visionText.text.trim()

                Log.d("DriverAI_OCR", "Texto OCR:\n$text")

                if (text.isBlank() || text == lastText) {
                    onComplete()
                    return@addOnSuccessListener
                }

                lastText = text

                val offer = parseOffer(text)

                if (offer == null) {
                    Log.d("DriverAI_OCR", "OCR leído, pero no parece oferta válida")
                    onComplete()
                    return@addOnSuccessListener
                }

                Log.d("DriverAI_OCR", "Oferta detectada: $offer")

                onOfferDetected(offer)
                onComplete()
            }
            .addOnFailureListener { e ->
                Log.e("DriverAI_OCR", "Error OCR: ${e.message}")
                onComplete()
            }
    }

    private fun parseOffer(text: String): OfferResult? {
        val fare = extractFare(text)

        if (fare <= 0) return null

        val totalDelivery = extractDeliveryTotal(text)
        val pickup = extractPickup(text)
        val trip = extractTrip(text)

        val totalKm: Double
        val totalMinutes: Int

        if (totalDelivery != null) {
            totalKm = totalDelivery.km
            totalMinutes = totalDelivery.minutes
        } else {
            val pickupKm = pickup?.km ?: 0.0
            val tripKm = trip?.km ?: 0.0

            totalKm = pickupKm + tripKm
            totalMinutes = (pickup?.minutes ?: 0) + (trip?.minutes ?: 0)
        }

        Log.d(
            "DriverAI_OCR",
            "Parse => fare=$fare totalKm=$totalKm totalMin=$totalMinutes"
        )

        if (totalKm <= 0 || totalMinutes <= 0) return null

        val maintenanceCost = totalKm * 30.0
        val netProfit = fare - maintenanceCost
        val profitPerKm = netProfit / totalKm

        val decision = when {
            profitPerKm >= 300 -> "ACEPTAR"
            profitPerKm >= 225 -> "REVISAR"
            else -> "RECHAZAR"
        }

        val color = when (decision) {
            "ACEPTAR" -> "#22C55E"
            "REVISAR" -> "#F59E0B"
            else -> "#EF4444"
        }

        return OfferResult(
            decision = decision,
            color = color,
            fare = fare,
            totalKm = totalKm,
            totalMinutes = totalMinutes,
            profitPerKm = profitPerKm,
            netProfit = netProfit
        )
    }

    private fun extractFare(text: String): Double {
        val normalized = text
            .replace("CRC", "₡", ignoreCase = true)
            .replace("¢", "₡")
            .replace("₵", "₡")

        val regexes = listOf(
            Regex("""₡\s*([0-9][0-9 .,\u00A0]*)"""),
            Regex("""(?:CRC|COLONES?)\s*([0-9][0-9 .,\u00A0]*)""", RegexOption.IGNORE_CASE),
            Regex("""([0-9]{3,6}(?:[.,][0-9]{2})?)\s*(?:CRC|COLONES?)""", RegexOption.IGNORE_CASE)
        )

        for (regex in regexes) {
            val match = regex.find(normalized)
            if (match != null) {
                return parseMoney(match.groupValues[1])
            }
        }

        return 0.0
    }

    private fun extractDeliveryTotal(text: String): TimeDistance? {
        val regexes = listOf(
            Regex(
                """Total[:\s]+([0-9]+)\s*min\s*\(([0-9]+(?:[.,][0-9]+)?)\s*km\)""",
                RegexOption.IGNORE_CASE
            ),
            Regex(
                """([0-9]+)\s*min\s*\(([0-9]+(?:[.,][0-9]+)?)\s*km\)""",
                RegexOption.IGNORE_CASE
            )
        )

        for (regex in regexes) {
            val match = regex.find(text)
            if (match != null) {
                return TimeDistance(
                    minutes = match.groupValues[1].toIntOrNull() ?: 0,
                    km = parseDecimal(match.groupValues[2])
                )
            }
        }

        return null
    }

    private fun extractPickup(text: String): TimeDistance? {
        val regex = Regex(
            """A\s+([0-9]+)\s*min\s*\(([0-9]+(?:[.,][0-9]+)?)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val match = regex.find(text) ?: return null

        return TimeDistance(
            minutes = match.groupValues[1].toIntOrNull() ?: 0,
            km = parseDecimal(match.groupValues[2])
        )
    }

    private fun extractTrip(text: String): TimeDistance? {
        val regex = Regex(
            """Viaje[:\s]+([0-9]+)\s*min\s*\(([0-9]+(?:[.,][0-9]+)?)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val match = regex.find(text) ?: return null

        return TimeDistance(
            minutes = match.groupValues[1].toIntOrNull() ?: 0,
            km = parseDecimal(match.groupValues[2])
        )
    }

    private fun parseMoney(value: String): Double {
        var clean = value.trim()
            .replace(Regex("""[\s\u00A0]"""), "")

        clean = when {
            clean.contains(".") && clean.contains(",") -> {
                clean.replace(".", "").replace(",", ".")
            }

            clean.contains(".") -> {
                val parts = clean.split(".")
                if (parts.last().length == 3) clean.replace(".", "") else clean
            }

            clean.contains(",") -> {
                val parts = clean.split(",")
                if (parts.last().length == 3) clean.replace(",", "") else clean.replace(",", ".")
            }

            else -> clean
        }

        return clean.toDoubleOrNull() ?: 0.0
    }

    private fun parseDecimal(value: String): Double {
        return value.trim()
            .replace(",", ".")
            .toDoubleOrNull() ?: 0.0
    }

    data class TimeDistance(
        val minutes: Int,
        val km: Double
    )

    data class OfferResult(
        val decision: String,
        val color: String,
        val fare: Double,
        val totalKm: Double,
        val totalMinutes: Int,
        val profitPerKm: Double,
        val netProfit: Double
    )
}