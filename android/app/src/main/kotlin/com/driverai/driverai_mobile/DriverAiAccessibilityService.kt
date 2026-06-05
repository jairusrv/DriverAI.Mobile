package com.driverai.driverai_mobile

import android.accessibilityservice.AccessibilityService
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.LinearLayout
import android.widget.TextView

class DriverAiAccessibilityService : AccessibilityService() {

    private var lastText = ""
    private var overlayView: LinearLayout? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return

        Log.d("DriverAI_ACCESS", "Evento desde package: $packageName")

        val root = rootInActiveWindow ?: event.source ?: return
        val text = collectText(root)

        if (text.isBlank()) return

        Log.d("DriverAI_ACCESS", "Texto leído:\n$text")

        if (text == lastText) return
        lastText = text

        MainActivity.lastNotificationProvider = packageName
        MainActivity.lastNotificationText = text

        if (!looksLikeRideOffer(text)) return

        val result = analyzeOffer(text)

        if (result != null) {
            Log.d("DriverAI_ACCESS", "Oferta detectada: $result")
            showNativeOverlay(result)
        } else {
            Log.d("DriverAI_ACCESS", "Texto parece oferta, pero no se pudo calcular.")
        }
    }

    override fun onInterrupt() {}

    private fun collectText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""

        val builder = StringBuilder()

        node.text?.toString()?.let {
            if (it.isNotBlank()) builder.append(it).append("\n")
        }

        node.contentDescription?.toString()?.let {
            if (it.isNotBlank()) builder.append(it).append("\n")
        }

        for (i in 0 until node.childCount) {
            builder.append(collectText(node.getChild(i)))
        }

        return builder.toString()
            .lines()
            .map { it.trim() }
            .filter { it.isNotBlank() }
            .distinct()
            .joinToString("\n")
    }

    private fun looksLikeRideOffer(text: String): Boolean {
        val lower = text.lowercase()

        return text.contains("₡") ||
            text.contains("¢") ||
            lower.contains("total:") ||
            lower.contains("viaje:") ||
            lower.contains("entrega") ||
            lower.contains("exclusivo")
    }

    private fun analyzeOffer(text: String): String? {
        val fare = extractFare(text)
        val totalKm = extractTotalKm(text)
        val totalMinutes = extractTotalMinutes(text)

        Log.d(
            "DriverAI_ACCESS",
            "Parse result => fare=$fare km=$totalKm minutes=$totalMinutes"
        )

        if (fare <= 0 || totalKm <= 0) return null

        val maintenance = totalKm * 30.0
        val net = fare - maintenance
        val perKm = net / totalKm

        val decision = when {
            perKm >= 300 -> "ACEPTAR"
            perKm >= 225 -> "ACEPTABLE"
            else -> "RECHAZAR"
        }

        val color = when (decision) {
            "ACEPTAR" -> "#22C55E"
            "ACEPTABLE" -> "#F59E0B"
            else -> "#EF4444"
        }

        return "$decision|$color|₡${"%.2f".format(perKm)} / km|🚗 ${"%.1f".format(totalKm)} km | ⏱ $totalMinutes min|🔧 ₡${"%.0f".format(maintenance)} | 📈 ₡${"%.0f".format(net)}"
    }

    private fun extractFare(text: String): Double {
        val regex = Regex("""[₡¢]\s?([0-9\s.,]+)""")
        val match = regex.find(text) ?: return 0.0

        return parseMoney(match.groupValues[1])
    }

    private fun extractTotalKm(text: String): Double {
        val deliveryRegex = Regex(
            """Total:\s*.*?\(([0-9.,]+)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val delivery = deliveryRegex.find(text)

        if (delivery != null) {
            return parseDecimal(delivery.groupValues[1])
        }

        val pickupRegex = Regex(
            """A\s+[0-9]+\s+min\s+\(([0-9.,]+)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val tripRegex = Regex(
            """Viaje:\s*.*?\(([0-9.,]+)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val pickup = pickupRegex.find(text)
        val trip = tripRegex.find(text)

        val pickupKm = pickup?.let {
            parseDecimal(it.groupValues[1])
        } ?: 0.0

        val tripKm = trip?.let {
            parseDecimal(it.groupValues[1])
        } ?: 0.0

        return pickupKm + tripKm
    }

    private fun extractTotalMinutes(text: String): Int {
        val totalRegex = Regex(
            """Total:\s*([0-9]+)\s*min""",
            RegexOption.IGNORE_CASE
        )

        val total = totalRegex.find(text)

        if (total != null) {
            return total.groupValues[1].toIntOrNull() ?: 0
        }

        val tripRegex = Regex(
            """Viaje:\s*([0-9]+)\s*min""",
            RegexOption.IGNORE_CASE
        )

        val pickupRegex = Regex(
            """A\s+([0-9]+)\s+min""",
            RegexOption.IGNORE_CASE
        )

        val trip = tripRegex.find(text)
        val pickup = pickupRegex.find(text)

        val tripMin = trip?.groupValues?.get(1)?.toIntOrNull() ?: 0
        val pickupMin = pickup?.groupValues?.get(1)?.toIntOrNull() ?: 0

        return tripMin + pickupMin
    }

    private fun parseMoney(value: String): Double {
        var clean = value.trim().replace(" ", "")

        clean = if (clean.contains(",") && clean.contains(".")) {
            clean.replace(".", "").replace(",", ".")
        } else if (clean.contains(",")) {
            clean.replace(",", ".")
        } else {
            clean
        }

        return clean.toDoubleOrNull() ?: 0.0
    }

    private fun parseDecimal(value: String): Double {
        return value.trim()
            .replace(",", ".")
            .toDoubleOrNull() ?: 0.0
    }

    private fun showNativeOverlay(raw: String) {
        val parts = raw.split("|")
        if (parts.size < 6) return

        val decision = parts[0]
        val color = Color.parseColor(parts[1])
        val perKm = parts[2]
        val kmTime = parts[3]
        val maintenance = parts[4]
        val net = parts[5]

        removeOverlay()

        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(28, 18, 28, 18)
        layout.setBackgroundColor(Color.parseColor("#EE151515"))

        fun label(
            value: String,
            size: Float,
            textColor: Int,
            bold: Boolean = true
        ): TextView {
            val tv = TextView(this)
            tv.text = value
            tv.textSize = size
            tv.setTextColor(textColor)
            tv.gravity = Gravity.CENTER
            if (bold) tv.setTypeface(null, 1)
            return tv
        }

        layout.addView(label(decision, 18f, color))
        layout.addView(label(perKm, 26f, color))
        layout.addView(label(kmTime, 14f, Color.WHITE))
        layout.addView(label("$maintenance  $net", 13f, Color.WHITE))

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 90

        val wm = getSystemService(WINDOW_SERVICE) as WindowManager
        wm.addView(layout, params)

        overlayView = layout

        handler.postDelayed({
            removeOverlay()
        }, 9000)
    }

    private fun removeOverlay() {
        val view = overlayView ?: return

        try {
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
        } catch (_: Exception) {
        }

        overlayView = null
    }
}