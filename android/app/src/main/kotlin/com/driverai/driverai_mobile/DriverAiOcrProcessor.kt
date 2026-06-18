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

    private val recognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    fun process(bitmap: Bitmap, onOfferDetected: (OfferResult) -> Unit, onComplete: () -> Unit) {
        val image = InputImage.fromBitmap(bitmap, 0)

        recognizer
                .process(image)
                .addOnSuccessListener { visionText ->
                    val rawText = visionText.text.trim()

                    val text = normalizeOcrText(rawText)

                    if (DEBUG_OCR_TEXT) {
                        Log.d(TAG, "Texto OCR:\n$text")
                    }

                    if (text.isBlank()) {
                        onComplete()
                        return@addOnSuccessListener
                    }

                    val offer = parseOffer(text)

                    if (offer == null) {
                        onComplete()
                        return@addOnSuccessListener
                    }

                    Log.d(TAG, "Oferta detectada: $offer")

                    onOfferDetected(offer)
                    onComplete()
                }
                .addOnFailureListener { e ->
                    Log.e(TAG, "Error OCR: ${e.message}")

                    onComplete()
                }
    }

    private fun parseOffer(text: String): OfferResult? {
        val provider = detectProvider(text)
        val resolvedProvider = resolveProviderType(provider, text)

        if (resolvedProvider == Provider.UNKNOWN) return null

        if (provider == Provider.UNKNOWN) return null

        val fare = extractFare(text, resolvedProvider)

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

        if (fare <= 0) return null

        if (totalKm <= 0 || totalMinutes <= 0) return null

        val maintenanceCost = totalKm * 30.0

        val netProfit = fare - maintenanceCost

        val profitPerKm = netProfit / totalKm

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
        val destinationText = extractDestinationText(text)

        return OfferResult(
                provider = resolvedProvider.name,
                decision = decision,
                color = color,
                fare = fare,
                totalKm = totalKm,
                totalMinutes = totalMinutes,
                profitPerKm = profitPerKm,
                netProfit = netProfit,
                destinationText = destinationText
        )
    }
    
    private fun resolveProviderType(
    provider: Provider,
    text: String
): Provider {
    val lower =
        text.lowercase()

    if (provider == Provider.UBER) {
        val isUberEats =
            lower.contains("entrega") ||
                lower.contains("delivery") ||
                lower.contains("pedido") ||
                lower.contains("restaurante")

        if (isUberEats) {
            return Provider.UBER_EATS
        }

        return Provider.UBER_RIDE
    }

    return provider
}

    private fun removeNoise(text: String): String {
    val noiseRegex =
        Regex("""(?i)^(?:google|maps?|buscar|inicio|chat|notificaciones?|ajustes?|libre|ocupado|desempeño|perfil|menu|menú|\d{1,2}:\d{2})$""")

    return text
        .lines()
        .map { it.trim() }
        .filter { it.isNotBlank() }
        .filterNot { noiseRegex.matches(it) }
        .joinToString("\n")
}

private fun resolveProviderType(
    provider: Provider,
    text: String
): Provider {
    val lower = text.lowercase()

    if (provider == Provider.UBER) {
        val isUberEats =
            lower.contains("entrega") ||
                lower.contains("delivery") ||
                lower.contains("pedido") ||
                lower.contains("restaurante")

        return if (isUberEats) {
            Provider.UBER_EATS
        } else {
            Provider.UBER_RIDE
        }
    }

    return provider
}

    private fun detectProvider(text: String): Provider {
    val cleanText = removeNoise(text)

    val platformRegex =
        Regex("""(?i)\b(?:uber|didi|cabify|lyft|99|indriver|in drive)\b""")

    val match = platformRegex.find(cleanText)

    if (match != null) {
        return when (
            match.value
                .lowercase()
                .replace(" ", "")
        ) {
            "uber" -> Provider.UBER
            "didi" -> Provider.DIDI
            "cabify" -> Provider.CABIFY
            "lyft" -> Provider.LYFT
            "99" -> Provider.NINETY_NINE
            "indriver",
            "indrive" -> Provider.INDRIVE
            else -> Provider.UNKNOWN
        }
    }

    val hasAccept =
        Regex("""(?i)\b(?:aceptar|accept|aceitar)\b""")
            .containsMatchIn(cleanText)

    val hasPrice =
        Regex("""(?i)(?:₡|CRC|COLONES?|\$|USD|€|MXN|COP|ARS|PEN|DOP|BRL)\s*[0-9][0-9 .,\u00A0]*""")
            .containsMatchIn(cleanText)

    if (hasAccept && hasPrice) {
        return Provider.UNKNOWN_RIDE
    }

    return Provider.UNKNOWN
}

    private fun normalizeOcrText(text: String): String {
        return text.replace("\u00A0", " ")
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
    val normalized =
        text
            .replace("CRC", "₡", ignoreCase = true)
            .replace("COLONES", "₡", ignoreCase = true)
            .replace("COLON", "₡", ignoreCase = true)
            .replace("¢", "₡")
            .replace("₵", "₡")

    val currencyRegexes =
        listOf(
            Regex("""[₡$€]\s*([0-9][0-9 .,\u00A0]*)"""),
            Regex("""([0-9]{3,7}(?:[.,][0-9]{2})?)\s*(?:CRC|USD|EUR|MXN|COP|ARS|PEN|BRL)""", RegexOption.IGNORE_CASE),
            Regex("""(?:tarifa|pago|ganancia|recibes|recibirás|total|precio)\s*[:\-]?\s*[₡$€]?\s*([0-9][0-9 .,\u00A0]*)""", RegexOption.IGNORE_CASE),
            Regex("""(?:aceptar|accept|aceitar)\s*(?:por|for)?\s*[₡$€]?\s*([0-9][0-9 .,\u00A0]*)""", RegexOption.IGNORE_CASE)
        )

    for (regex in currencyRegexes) {
        val match = regex.find(normalized)

        if (match != null) {
            val amount = parseMoney(match.groupValues[1])

            if (amount >= 300.0) {
                return amount
            }
        }
    }

    val fallbackNumbers =
        Regex("""\b([0-9]{3,7}(?:[.,][0-9]{2})?)\b""")
            .findAll(normalized)
            .map { it.groupValues[1] to it.range }
            .filterNot { (_, range) ->
                val start = (range.first - 18).coerceAtLeast(0)
                val end = (range.last + 18).coerceAtMost(normalized.length - 1)

                val context =
                    normalized.substring(start, end).lowercase()

                listOf(
                    "min",
                    "km",
                    "calle",
                    "avenida",
                    "ruta",
                    "tel",
                    "otp",
                    "pin",
                    "código",
                    "codigo"
                ).any { context.contains(it) }
            }
            .map { (raw, _) -> parseMoney(raw) }
            .filter { it >= 300.0 }
            .toList()

    return fallbackNumbers.firstOrNull() ?: 0.0
}

    private fun extractDeliveryTotal(
    text: String
): TimeDistance? {
    val regexes =
        listOf(
            Regex(
                """(?:total|duración|duracion|tiempo\s*total)?[:\s]*([0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\s*\)?""",
                RegexOption.IGNORE_CASE
            ),
            Regex(
                """([0-9OIl]+)\s*min\s*[•\-|]\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km""",
                RegexOption.IGNORE_CASE
            )
        )

    for (regex in regexes) {
        val match = regex.find(text)

        if (match != null) {
            val minutes =
                cleanNumber(match.groupValues[1]).toIntOrNull() ?: 0

            val km =
                parseDecimal(cleanNumber(match.groupValues[2]))

            if (minutes > 0 && km > 0) {
                return TimeDistance(
                    minutes = minutes,
                    km = km,
                )
            }
        }
    }

    return null
}

    private fun extractPickup(
    text: String
): TimeDistance? {
    val regexes =
        listOf(
            Regex(
                """(?:a|recogida|pickup|llegar|hasta)\s+([0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\s*\)?""",
                RegexOption.IGNORE_CASE
            ),
            Regex(
                """([0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\s*\)?\s*(?:hasta|recogida|pickup)""",
                RegexOption.IGNORE_CASE
            )
        )

    for (regex in regexes) {
        val match = regex.find(text)

        if (match != null) {
            val minutes =
                cleanNumber(match.groupValues[1]).toIntOrNull() ?: 0

            val km =
                parseDecimal(cleanNumber(match.groupValues[2]))

            if (minutes > 0 && km > 0) {
                return TimeDistance(
                    minutes = minutes,
                    km = km,
                )
            }
        }
    }

    return null
}

    private fun extractTrip(
    text: String
): TimeDistance? {
    val regexes =
        listOf(
            Regex(
                """(?:viaje|trip|destino|entrega|delivery)\s*[:\s]+([0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\s*\)?""",
                RegexOption.IGNORE_CASE
            ),
            Regex(
                """([0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*km\s*\)?\s*(?:viaje|trip|destino|entrega|delivery)""",
                RegexOption.IGNORE_CASE
            )
        )

    for (regex in regexes) {
        val match = regex.find(text)

        if (match != null) {
            val minutes =
                cleanNumber(match.groupValues[1]).toIntOrNull() ?: 0

            val km =
                parseDecimal(cleanNumber(match.groupValues[2]))

            if (minutes > 0 && km > 0) {
                return TimeDistance(
                    minutes = minutes,
                    km = km,
                )
            }
        }
    }

    return null
}

    private fun cleanNumber(value: String): String {
        return value.replace("O", "0")
                .replace("o", "0")
                .replace("I", "1")
                .replace("l", "1")
                .replace("|", "1")
                .trim()
    }

    private fun parseMoney(value: String): Double {
        var clean = cleanNumber(value).replace(Regex("""[\s\u00A0]"""), "")

        clean =
                when {
                    clean.contains(".") && clean.contains(",") -> {
                        clean.replace(".", "").replace(",", ".")
                    }
                    clean.contains(".") -> {
                        val parts = clean.split(".")

                        if (parts.last().length == 3) clean.replace(".", "") else clean
                    }
                    clean.contains(",") -> {
                        val parts = clean.split(",")

                        if (parts.last().length == 3) clean.replace(",", "")
                        else clean.replace(",", ".")
                    }
                    else -> clean
                }

        return clean.toDoubleOrNull() ?: 0.0
    }

    private fun parseDecimal(value: String): Double {
        return cleanNumber(value).replace(",", ".").toDoubleOrNull() ?: 0.0
    }

    private fun extractDestinationText(text: String): String? {

        val lines = text.lines().map { it.trim() }.filter { it.isNotBlank() }

        val candidates =
                lines.filter {
                    it.length > 5 &&
                            !it.contains("aceptar", true) &&
                            !it.contains("min", true) &&
                            !it.contains("km", true) &&
                            !it.contains("₡") &&
                            !it.contains("total", true) &&
                            !it.contains("viaje", true)
                }

        return candidates.takeLast(3).joinToString(", ").ifBlank { null }
    }

    enum class Provider {
        UBER,
        UBER_EATS,
        UBER_RIDE,
        DIDI,
        INDRIVE,
        CABIFY,
        LYFT,
        NINETY_NINE,
        UNKNOWN_RIDE,
        UNKNOWN
    }

    data class TimeDistance(val minutes: Int, val km: Double)

    data class OfferResult(
            val provider: String,
            val decision: String,
            val color: String,
            val fare: Double,
            val totalKm: Double,
            val totalMinutes: Int,
            val profitPerKm: Double,
            val netProfit: Double,
            val destinationText: String?
    )
}
