package com.driverai.driverai_mobile

import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class DriverAiOcrProcessor {

    companion object {
        private const val TAG = "DriverAI_OCR"
        private const val DEBUG_OCR_TEXT = false
    }

   

    private val recognizer =
        TextRecognition.getClient(
            TextRecognizerOptions.DEFAULT_OPTIONS
        )

    fun process(
        bitmap: Bitmap,
        onOfferDetected: (OfferResult) -> Unit,
        onComplete: () -> Unit
    ) {
        val image =
            InputImage.fromBitmap(
                bitmap,
                0
            )

        recognizer.process(image)
            .addOnSuccessListener { visionText ->

                val rawText =
                    visionText.text.trim()

                val text =
                    normalizeOcrText(rawText)

                if (DEBUG_OCR_TEXT) {
                    Log.d(
                        TAG,
                        "Texto OCR:\n$text"
                    )
                }

                if (text.isBlank()) {
                    onComplete()
                    return@addOnSuccessListener
                }

                val offer =
                    parseOffer(text)

                if (offer == null) {
                    onComplete()
                    return@addOnSuccessListener
                }

                Log.d(
                    TAG,
                    "Oferta detectada: $offer"
                )

                onOfferDetected(offer)
                onComplete()
            }
            .addOnFailureListener { e ->

                Log.e(
                    TAG,
                    "Error OCR: ${e.message}"
                )

                onComplete()
            }
    }

    private fun parseOffer(
        text: String
    ): OfferResult? {
        val provider =
            detectProvider(text)

        if (provider == Provider.UNKNOWN)
            return null

        val fare =
            extractFare(
                text,
                provider
            )

        val totalDelivery =
            extractDeliveryTotal(text)

        val pickup =
            extractPickup(text)

        val trip =
            extractTrip(text)

        val totalKm: Double
        val totalMinutes: Int

        if (totalDelivery != null) {
            totalKm =
                totalDelivery.km

            totalMinutes =
                totalDelivery.minutes
        } else {
            val pickupKm =
                pickup?.km ?: 0.0

            val tripKm =
                trip?.km ?: 0.0

            totalKm =
                pickupKm + tripKm

            totalMinutes =
                (pickup?.minutes ?: 0) +
                    (trip?.minutes ?: 0)
        }

        if (fare <= 0)
            return null

        if (totalKm <= 0 || totalMinutes <= 0)
            return null

        val maintenanceCost =
            totalKm * 30.0

        val netProfit =
            fare - maintenanceCost

        val profitPerKm =
            netProfit / totalKm

        val decision =
            when {
                profitPerKm >= 300 -> "ACEPTAR"
                profitPerKm >= 225 -> "REVISAR"
                else -> "RECHAZAR"
            }

        val color =
            when (decision) {
                "ACEPTAR" -> "#22C55E"
                "REVISAR" -> "#F59E0B"
                else -> "#EF4444"
            }

        return OfferResult(
            provider = provider.name,
            decision = decision,
            color = color,
            fare = fare,
            totalKm = totalKm,
            totalMinutes = totalMinutes,
            profitPerKm = profitPerKm,
            netProfit = netProfit
        )
    }

    private fun detectProvider(
        text: String
    ): Provider {
        val lower =
            text.lowercase()

        val isUberEats =
            lower.contains("entrega") &&
                lower.contains("total") &&
                lower.contains("aceptar")

        if (isUberEats)
            return Provider.UBER_EATS

        val isUberRide =
            lower.contains("uberx") ||
                lower.contains("comfort") ||
                lower.contains("flash") ||
                (
                    lower.contains("viaje") &&
                        lower.contains("aceptar") &&
                        lower.contains("min")
                )

        if (isUberRide)
            return Provider.UBER_RIDE

        val isDidi =
            lower.contains("didi") ||
                lower.contains("di di") ||
                (
                    lower.contains("tarifa") &&
                        lower.contains("aceptar")
                )

        if (isDidi)
            return Provider.DIDI

        val isInDrive =
            lower.contains("indrive") ||
                lower.contains("in drive")

        if (isInDrive)
            return Provider.INDRIVE

        return Provider.UNKNOWN
    }

    private fun normalizeOcrText(
        text: String
    ): String {
        return text
            .replace("\u00A0", " ")
            .replace("YP Entrega", "Entrega", ignoreCase = true)
            .replace("Y? Entrega", "Entrega", ignoreCase = true)
            .replace("P Entrega", "Entrega", ignoreCase = true)
            .replace("O Total", "Total", ignoreCase = true)
            .replace("9 Total", "Total", ignoreCase = true)
            .replace(") Total", "Total", ignoreCase = true)
            .replace("( Total", "Total", ignoreCase = true)
            .replace("C.tago", "Cartago", ignoreCase = true)
            .replace("G.tago", "Cartago", ignoreCase = true)
            .replace("Cart:go", "Cartago", ignoreCase = true)
            .replace("Cartgo", "Cartago", ignoreCase = true)
            .replace(Regex("""\bC(?=\d)"""), "₡")
            .trim()
    }

    private fun extractFare(
        text: String,
        provider: Provider
    ): Double {
        val regexes =
            listOf(
                Regex("""[₡C]\s*([0-9][0-9 .,\u00A0]*)"""),
                Regex(
                    """(?:CRC|COLONES?)\s*([0-9][0-9 .,\u00A0]*)""",
                    RegexOption.IGNORE_CASE
                ),
                Regex(
                    """([0-9]{3,6}(?:[.,][0-9]{2})?)\s*(?:CRC|COLONES?)""",
                    RegexOption.IGNORE_CASE
                )
            )

        for (regex in regexes) {
            val match =
                regex.find(text)

            if (match != null) {
                val amount =
                    parseMoney(
                        match.groupValues[1]
                    )

                if (amount > 0)
                    return amount
            }
        }

        val looksLikeOffer =
            provider != Provider.UNKNOWN &&
                text.contains(
                    "aceptar",
                    true
                )

        if (!looksLikeOffer)
            return 0.0

        val fallbackRegex =
            Regex(
                """\b([0-9]{1,3}(?:[ .][0-9]{3})*(?:,[0-9]{2})?|[0-9]{3,6}(?:,[0-9]{2})?)\b"""
            )

        val ignoredNearbyWords =
            listOf(
                "min",
                "km",
                "calle",
                "avenida",
                "transversal",
                "ruta",
                "via",
                "vía",
                "total"
            )

        val candidates =
            fallbackRegex.findAll(text)
                .map { match ->
                    val raw =
                        match.groupValues[1]

                    val start =
                        (match.range.first - 14)
                            .coerceAtLeast(0)

                    val end =
                        (match.range.last + 14)
                            .coerceAtMost(text.length - 1)

                    val context =
                        text.substring(
                            start,
                            end
                        ).lowercase()

                    raw to context
                }
                .filterNot { (_, context) ->
                    ignoredNearbyWords.any {
                        context.contains(it)
                    }
                }
                .map { (raw, _) ->
                    raw to parseMoney(raw)
                }
                .filter { (_, value) ->
                    value >= 300.0
                }
                .toList()

        return candidates
            .firstOrNull()
            ?.second ?: 0.0
    }

    private fun extractDeliveryTotal(
        text: String
    ): TimeDistance? {
        val regexes =
            listOf(
                Regex(
                    """Total[:\s]+([0-9OIl]+)\s*min\s*\(([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\)""",
                    RegexOption.IGNORE_CASE
                ),
                Regex(
                    """([0-9OIl]+)\s*min\s*\(([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\)""",
                    RegexOption.IGNORE_CASE
                )
            )

        for (regex in regexes) {
            val match =
                regex.find(text)

            if (match != null) {
                return TimeDistance(
                    minutes = cleanNumber(
                        match.groupValues[1]
                    ).toIntOrNull() ?: 0,
                    km = parseDecimal(
                        cleanNumber(
                            match.groupValues[2]
                        )
                    )
                )
            }
        }

        return null
    }

    private fun extractPickup(
        text: String
    ): TimeDistance? {
        val regex =
            Regex(
                """A\s+([0-9OIl]+)\s*min\s*\(([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\)""",
                RegexOption.IGNORE_CASE
            )

        val match =
            regex.find(text) ?: return null

        return TimeDistance(
            minutes = cleanNumber(
                match.groupValues[1]
            ).toIntOrNull() ?: 0,
            km = parseDecimal(
                cleanNumber(
                    match.groupValues[2]
                )
            )
        )
    }

    private fun extractTrip(
        text: String
    ): TimeDistance? {
        val regex =
            Regex(
                """Viaje[:\s]+([0-9OIl]+)\s*min\s*\(([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\)""",
                RegexOption.IGNORE_CASE
            )

        val match =
            regex.find(text) ?: return null

        return TimeDistance(
            minutes = cleanNumber(
                match.groupValues[1]
            ).toIntOrNull() ?: 0,
            km = parseDecimal(
                cleanNumber(
                    match.groupValues[2]
                )
            )
        )
    }

    private fun cleanNumber(
        value: String
    ): String {
        return value
            .replace("O", "0")
            .replace("o", "0")
            .replace("I", "1")
            .replace("l", "1")
            .replace("|", "1")
            .trim()
    }

    private fun parseMoney(
        value: String
    ): Double {
        var clean =
            cleanNumber(value)
                .replace(
                    Regex("""[\s\u00A0]"""),
                    ""
                )

        clean =
            when {
                clean.contains(".") &&
                    clean.contains(",") -> {
                    clean
                        .replace(".", "")
                        .replace(",", ".")
                }

                clean.contains(".") -> {
                    val parts =
                        clean.split(".")

                    if (parts.last().length == 3)
                        clean.replace(".", "")
                    else
                        clean
                }

                clean.contains(",") -> {
                    val parts =
                        clean.split(",")

                    if (parts.last().length == 3)
                        clean.replace(",", "")
                    else
                        clean.replace(",", ".")
                }

                else -> clean
            }

        return clean
            .toDoubleOrNull() ?: 0.0
    }

    private fun parseDecimal(
        value: String
    ): Double {
        return cleanNumber(value)
            .replace(",", ".")
            .toDoubleOrNull() ?: 0.0
    }

    enum class Provider {
        UBER_EATS,
        UBER_RIDE,
        DIDI,
        INDRIVE,
        UNKNOWN
    }

    data class TimeDistance(
        val minutes: Int,
        val km: Double
    )

    data class OfferResult(
        val provider: String,
        val decision: String,
        val color: String,
        val fare: Double,
        val totalKm: Double,
        val totalMinutes: Int,
        val profitPerKm: Double,
        val netProfit: Double
    )
}