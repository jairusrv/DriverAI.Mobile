package com.driverai.driverai_mobile

import android.accessibilityservice.AccessibilityService
import android.graphics.PixelFormat
import android.os.Handler
import android.os.Looper
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.TextView
import android.graphics.Color
import android.view.ViewGroup
import android.widget.LinearLayout

class DriverAiAccessibilityService : AccessibilityService() {

    private var lastText = ""
    private var overlayView: LinearLayout? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return

        if (!packageName.contains("uber", ignoreCase = true) &&
            !packageName.contains("didi", ignoreCase = true)
        ) return

        val root = rootInActiveWindow ?: return
        val text = collectText(root)

        if (text.length < 20 || text == lastText) return

        lastText = text

        MainActivity.lastNotificationProvider = packageName
        MainActivity.lastNotificationText = text

        val result = analyzeOffer(text)

        if (result != null) {
            showNativeOverlay(result)
        }
    }

    override fun onInterrupt() {}

    private fun collectText(node: AccessibilityNodeInfo?): String {
        if (node == null) return ""

        val builder = StringBuilder()

        node.text?.let {
            if (it.isNotBlank()) builder.append(it).append("\n")
        }

        for (i in 0 until node.childCount) {
            builder.append(collectText(node.getChild(i)))
        }

        return builder.toString().trim()
    }

    private fun analyzeOffer(text: String): String? {
        val fare = extractFare(text)
        val totalKm = extractTotalKm(text)

        if (fare <= 0 || totalKm <= 0) return null

        val perKm = fare / totalKm

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

        return "$decision|$color|₡${"%.2f".format(perKm)} / km|🚗 ${"%.1f".format(totalKm)} km"
    }

    private fun extractFare(text: String): Double {
        val regex = Regex("""[₡¢]\s?([0-9\s.,]+)""")
        val match = regex.find(text) ?: return 0.0

        return parseNumber(match.groupValues[1])
    }

    private fun extractTotalKm(text: String): Double {
        val deliveryRegex = Regex(
            """Total:\s*.*?\(([0-9.,]+)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val delivery = deliveryRegex.find(text)

        if (delivery != null) {
            return parseNumber(delivery.groupValues[1])
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

        val pickupKm = pickup?.let { parseNumber(it.groupValues[1]) } ?: 0.0
        val tripKm = trip?.let { parseNumber(it.groupValues[1]) } ?: 0.0

        return pickupKm + tripKm
    }

    private fun parseNumber(value: String): Double {
        var clean = value.trim().replace(" ", "")

        clean = if (clean.contains(",") && clean.contains(".")) {
            clean.replace(".", "").replace(",", ".")
        } else {
            clean.replace(",", ".")
        }

        return clean.toDoubleOrNull() ?: 0.0
    }

    private fun showNativeOverlay(raw: String) {
        val parts = raw.split("|")
        if (parts.size < 4) return

        val decision = parts[0]
        val color = Color.parseColor(parts[1])
        val perKm = parts[2]
        val km = parts[3]

        removeOverlay()

        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(28, 18, 28, 18)
        layout.setBackgroundColor(Color.parseColor("#EE151515"))

        val title = TextView(this)
        title.text = decision
        title.setTextColor(color)
        title.textSize = 18f
        title.gravity = Gravity.CENTER
        title.setTypeface(null, 1)

        val value = TextView(this)
        value.text = perKm
        value.setTextColor(color)
        value.textSize = 25f
        value.gravity = Gravity.CENTER
        value.setTypeface(null, 1)

        val details = TextView(this)
        details.text = km
        details.setTextColor(Color.WHITE)
        details.textSize = 14f
        details.gravity = Gravity.CENTER
        details.setTypeface(null, 1)

        layout.addView(title)
        layout.addView(value)
        layout.addView(details)

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 80

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