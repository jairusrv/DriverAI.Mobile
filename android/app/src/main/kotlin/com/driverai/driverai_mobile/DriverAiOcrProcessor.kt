package com.driverai.driverai_mobile

import android.content.Context
import android.graphics.Bitmap
import android.util.Log
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class DriverAiOcrProcessor(
    private val context: Context
) {

    companion object {
        private const val TAG = "DriverAI_OCR"
        private const val DEBUG_OCR_TEXT = false
    }

    private val recognizer =
        TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    fun process(
        bitmap: Bitmap,
        onOfferDetected: (OfferResult) -> Unit,
        onComplete: () -> Unit
    ) {
        val image = InputImage.fromBitmap(bitmap, 0)

        recognizer.process(image)
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
                    if (looksLikePossibleOffer(text)) {
                        Log.d(TAG, "OCR posible oferta no parseada:\n$text")
                        DriverAiOcrSampleLogger.save(context, text)
                    }

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

            val calculatedKm = pickupKm + tripKm
            val calculatedMinutes =
                (pickup?.minutes ?: 0) + (trip?.minutes ?: 0)

            val fallback =
                if (calculatedKm <= 0 || calculatedMinutes <= 0) {
                    extractAnyTimeDistance(text)
                } else {
                    null
                }

            totalKm =
                if (calculatedKm > 0) calculatedKm else fallback?.km ?: 0.0

            totalMinutes =
                if (calculatedMinutes > 0) calculatedMinutes else fallback?.minutes ?: 0
        }

        val isValidOffer =
            fare > 0 &&
                totalKm > 0 &&
                totalMinutes > 0 &&
                looksLikePossibleOffer(text)

        if (!isValidOffer) {
            return null
        }

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
        val coordinates = extractCoordinates(text)

        return OfferResult(
            provider = resolvedProvider.name,
            decision = decision,
            color = color,
            fare = fare,
            totalKm = totalKm,
            totalMinutes = totalMinutes,
            profitPerKm = profitPerKm,
            netProfit = netProfit,
            destinationText = destinationText,
            destinationLat = coordinates?.first,
            destinationLng = coordinates?.second
        )
    }

    private fun detectProvider(text: String): Provider {
        val cleanText = removeNoise(text)
        val lower = cleanText.lowercase()

        if (
            lower.contains("solicitud de viaje") ||
            lower.contains("ofrece tu tarifa") ||
            lower.contains("aceptar por crc") ||
            lower.contains("precio justo")
        ) {
            return Provider.INDRIVE
        }

        if (
            lower.contains("rechazo permitido") ||
            lower.contains("incluidos") ||
            lower.contains("dinámica") ||
            lower.contains("dinamica") ||
            lower.contains("parada") ||
            lower.contains("viajes")
        ) {
            return Provider.DIDI
        }

        val platformRegex =
            Regex("""(?i)\b(?:uber|didi|cabify|lyft|99|indriver|in drive)\b""")

        val match = platformRegex.find(cleanText)

        if (match != null) {
            return when (match.value.lowercase().replace(" ", "")) {
                "uber" -> Provider.UBER
                "didi" -> Provider.DIDI
                "cabify" -> Provider.CABIFY
                "lyft" -> Provider.LYFT
                "99" -> Provider.NINETY_NINE
                "indriver",
                "indrive" -> Provider.INDRIVE

                else -> Provider.UNKNOWN_RIDE
            }
        }

        return Provider.UNKNOWN_RIDE
    }

    private fun resolveProviderType(
        provider: Provider,
        text: String
    ): Provider {
        val lower = text.lowercase()

        if (provider == Provider.UBER) {
            val isDelivery =
                lower.contains("entrega") ||
                    lower.contains("delivery") ||
                    lower.contains("pedido") ||
                    lower.contains("restaurante") ||
                    lower.contains("artículo") ||
                    lower.contains("articulo") ||
                    lower.contains("total:")

            return if (isDelivery) {
                Provider.UBER_EATS
            } else {
                Provider.UBER_RIDE
            }
        }

        return provider
    }

    private fun removeNoise(text: String): String {
        val noiseRegex =
            Regex(
                """(?i)^(?:google|maps?|buscar|inicio|chat|notificaciones?|ajustes?|libre|ocupado|desempeño|perfil|menu|menú|\d{1,2}:\d{2})$"""
            )

        return text
            .lines()
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .filterNot { noiseRegex.matches(it) }
            .joinToString("\n")
    }

    private fun normalizeOcrText(text: String): String {
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
            .replace("metre", "metro", ignoreCase = true)
            .replace("metros", "metro", ignoreCase = true)
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
                Regex("""CRC\s*([0-9][0-9 .,\u00A0]*)""", RegexOption.IGNORE_CASE),
                Regex("""([0-9]{3,7}(?:[.,][0-9]{2})?)\s*(?:CRC|USD|EUR|MXN|COP|ARS|PEN|BRL)""", RegexOption.IGNORE_CASE),
                Regex("""(?:tarifa|pago|ganancia|recibes|recibirás|total|precio)\s*[:\-]?\s*[₡$€]?\s*([0-9][0-9 .,\u00A0]*)""", RegexOption.IGNORE_CASE),
                Regex("""(?:aceptar|accept|aceitar)\s*(?:por|for)?\s*(?:CRC|₡|USD|\$|€)?\s*([0-9][0-9 .,\u00A0]*)""", RegexOption.IGNORE_CASE)
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

                    val context = normalized.substring(start, end).lowercase()

                    listOf(
                        "min",
                        "km",
                        "metro",
                        "calle",
                        "avenida",
                        "ruta",
                        "tel",
                        "otp",
                        "pin",
                        "código",
                        "codigo",
                        "viajes",
                        "rating"
                    ).any { context.contains(it) }
                }
                .map { (raw, _) -> parseMoney(raw) }
                .filter { it >= 300.0 }
                .toList()

        return fallbackNumbers.firstOrNull() ?: 0.0
    }

    private fun extractDeliveryTotal(text: String): TimeDistance? {
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

        return firstValidTimeDistance(text, regexes)
    }

    private fun extractPickup(text: String): TimeDistance? {
        val regexes =
            listOf(
                Regex(
                    """(?:a|recogida|pickup|llegar|hasta)\s+((?:\d+\s*h\s*)?[0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*(km|m|metro)\s*\)?""",
                    RegexOption.IGNORE_CASE
                ),
                Regex(
                    """((?:\d+\s*h\s*)?[0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*(km|m|metro)\s*\)?\s*(?:hasta|recogida|pickup)""",
                    RegexOption.IGNORE_CASE
                )
            )

        return firstValidTimeDistance(text, regexes)
    }

    private fun extractTrip(text: String): TimeDistance? {
        val regexes =
            listOf(
                Regex(
                    """(?:viaje|trip|destino|entrega|delivery)\s*[:\s]+((?:\d+\s*h\s*)?[0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*(km|m|metro)\s*\)?""",
                    RegexOption.IGNORE_CASE
                ),
                Regex(
                    """((?:\d+\s*h\s*)?[0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*(km|m|metro)\s*\)?\s*(?:viaje|trip|destino|entrega|delivery)""",
                    RegexOption.IGNORE_CASE
                )
            )

        return firstValidTimeDistance(text, regexes)
    }

    private fun firstValidTimeDistance(
        text: String,
        regexes: List<Regex>
    ): TimeDistance? {
        for (regex in regexes) {
            val match = regex.find(text) ?: continue

            val rawMinutes = match.groupValues[1]
            val rawDistance = match.groupValues[2]
            val unit =
                if (match.groupValues.size > 3) {
                    match.groupValues[3]
                } else {
                    "km"
                }

            val minutes = parseMinutes(rawMinutes)
            val km = parseDistance(rawDistance, unit)

            if (minutes > 0 && km > 0) {
                return TimeDistance(minutes = minutes, km = km)
            }
        }

        return null
    }

    private fun extractAnyTimeDistance(text: String): TimeDistance? {
        val regex =
            Regex(
                """(?:(\d+)\s*h\s*)?([0-9OIl]+)\s*min\s*\(?\s*([0-9OIl]+(?:[.,][0-9OIl]+)?)\s*(km|m|metro)\s*\)?""",
                RegexOption.IGNORE_CASE
            )

        val matches =
            regex.findAll(text)
                .map { match ->
                    val hours = match.groupValues[1].toIntOrNull() ?: 0
                    val minutes =
                        cleanNumber(match.groupValues[2]).toIntOrNull() ?: 0

                    val km =
                        parseDistance(
                            match.groupValues[3],
                            match.groupValues[4]
                        )

                    TimeDistance(
                        minutes = hours * 60 + minutes,
                        km = km
                    )
                }
                .filter { it.minutes > 0 && it.km > 0 }
                .toList()

        if (matches.isEmpty()) {
            return null
        }

        return TimeDistance(
            minutes = matches.sumOf { it.minutes },
            km = matches.sumOf { it.km }
        )
    }

    private fun parseMinutes(value: String): Int {
        val normalized = value.lowercase()

        val hourMatch =
            Regex("""(\d+)\s*h""").find(normalized)

        val minuteMatch =
            Regex("""([0-9OIl]+)""").findAll(normalized).lastOrNull()

        val hours = hourMatch?.groupValues?.get(1)?.toIntOrNull() ?: 0
        val minutes =
            minuteMatch?.groupValues?.get(1)?.let {
                cleanNumber(it).toIntOrNull()
            } ?: 0

        return hours * 60 + minutes
    }

    private fun parseDistance(
        value: String,
        unit: String
    ): Double {
        val number =
            parseDecimal(
                cleanNumber(value)
            )

        val lowerUnit = unit.lowercase()

        return if (lowerUnit == "m" || lowerUnit.startsWith("metro")) {
            number / 1000.0
        } else {
            number
        }
    }

    private fun cleanNumber(value: String): String {
        return value
            .replace("O", "0")
            .replace("o", "0")
            .replace("I", "1")
            .replace("l", "1")
            .replace("|", "1")
            .trim()
    }

    private fun parseMoney(value: String): Double {
        var clean =
            cleanNumber(value)
                .replace(Regex("""[\s\u00A0]"""), "")

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
                    if (parts.last().length == 3) clean.replace(",", "") else clean.replace(",", ".")
                }

                else -> clean
            }

        return clean.toDoubleOrNull() ?: 0.0
    }

    private fun parseDecimal(value: String): Double {
        return cleanNumber(value)
            .replace(",", ".")
            .toDoubleOrNull() ?: 0.0
    }

    private fun extractDestinationText(text: String): String? {
        val lines =
            text.lines()
                .map { it.trim() }
                .filter { it.isNotBlank() }

        val candidates =
            lines.filter {
                it.length > 5 &&
                    !it.contains("aceptar", true) &&
                    !it.contains("omitir", true) &&
                    !it.contains("cerrar", true) &&
                    !it.contains("min", true) &&
                    !it.contains("km", true) &&
                    !it.contains("metro", true) &&
                    !it.contains("₡") &&
                    !it.contains("crc", true) &&
                    !it.contains("total", true) &&
                    !it.contains("viaje", true) &&
                    !it.contains("precio justo", true) &&
                    !it.contains("incluidos", true) &&
                    !it.contains("dinámica", true) &&
                    !it.contains("dinamica", true)
            }

        return candidates
            .takeLast(3)
            .joinToString(", ")
            .ifBlank { null }
    }

    private fun extractCoordinates(text: String): Pair<Double, Double>? {
        val regexes =
            listOf(
                Regex("""(-?\d{1,2}\.\d{4,})\s*,\s*(-?\d{1,3}\.\d{4,})"""),
                Regex(
                    """lat[:\s]*(-?\d{1,2}\.\d{4,}).*?(?:lng|lon|long)[:\s]*(-?\d{1,3}\.\d{4,})""",
                    RegexOption.IGNORE_CASE
                ),
                Regex(
                    """q=(-?\d{1,2}\.\d{4,}),(-?\d{1,3}\.\d{4,})""",
                    RegexOption.IGNORE_CASE
                )
            )

        for (regex in regexes) {
            val match = regex.find(text) ?: continue

            val lat = match.groupValues[1].toDoubleOrNull()
            val lng = match.groupValues[2].toDoubleOrNull()

            if (
                lat != null &&
                    lng != null &&
                    lat in -90.0..90.0 &&
                    lng in -180.0..180.0
            ) {
                return lat to lng
            }
        }

        return null
    }

    private fun looksLikePossibleOffer(text: String): Boolean {
        val cleanText = removeNoise(text)
        val lower = cleanText.lowercase()

        val hasPlatform =
            Regex(
                """(?i)\b(?:uber|didi|cabify|lyft|99|indriver|in drive)\b"""
            ).containsMatchIn(cleanText)

        val hasAccept =
            Regex(
                """(?i)\b(?:aceptar|accept|aceitar|omitir|viaje disponible|solicitud de viaje)\b"""
            ).containsMatchIn(cleanText)

        val hasMoney =
            Regex(
                """(?i)(?:₡|CRC|COLONES?|\$|USD|€|MXN|COP|ARS|PEN|DOP|BRL)\s*[0-9][0-9 .,\u00A0]*"""
            ).containsMatchIn(cleanText)

        val hasDistance =
            Regex(
                """(?i)[0-9OIl]+(?:[.,][0-9OIl]+)?\s*(?:km|m|metro)"""
            ).containsMatchIn(cleanText)

        val hasTime =
            Regex(
                """(?i)(?:\d+\s*h\s*)?[0-9OIl]+\s*min"""
            ).containsMatchIn(cleanText)

        val looksLikeDidi =
            lower.contains("rechazo permitido") ||
                lower.contains("incluidos") ||
                lower.contains("dinámica") ||
                lower.contains("dinamica") ||
                lower.contains("parada") ||
                lower.contains("viajes")

        val looksLikeInDrive =
            lower.contains("solicitud de viaje") ||
                lower.contains("precio justo") ||
                lower.contains("ofrece tu tarifa") ||
                lower.contains("aceptar por")

        return hasPlatform ||
            looksLikeDidi ||
            looksLikeInDrive ||
            (hasAccept && hasMoney) ||
            (hasMoney && hasDistance && hasTime)
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
        val netProfit: Double,
        val destinationText: String?,
        val destinationLat: Double? = null,
        val destinationLng: Double? = null
    )
}