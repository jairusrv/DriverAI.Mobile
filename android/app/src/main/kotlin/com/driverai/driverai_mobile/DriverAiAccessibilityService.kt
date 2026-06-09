package com.driverai.driverai_mobile

import android.accessibilityservice.AccessibilityService
import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.PixelFormat
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.widget.LinearLayout
import android.widget.TextView
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

class DriverAiAccessibilityService : AccessibilityService() {

    private val mainHandler = Handler(Looper.getMainLooper())

    private var overlayView: LinearLayout? = null
    private var lastOcrText = ""
    private var lastOcrTime = 0L
    private var isProcessingOcr = false

    override fun onServiceConnected() {
        super.onServiceConnected()
        Log.d("DriverAI_OCR", "AccessibilityService conectado")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName = event?.packageName?.toString() ?: return

        if (!isSupportedApp(packageName)) return

        val now = System.currentTimeMillis()

        if (isProcessingOcr) return

        if (now - lastOcrTime < 1200) return

        lastOcrTime = now

        Log.d("DriverAI_OCR", "Evento detectado desde: $packageName")

        mainHandler.postDelayed({
            try {
                captureScreenWithOcr()
            } catch (e: Exception) {
                Log.e("DriverAI_OCR", "Error ejecutando OCR: ${e.message}")
                isProcessingOcr = false
            }
        }, 650)
    }

    override fun onInterrupt() {}

    private fun isSupportedApp(packageName: String): Boolean {
        val lower = packageName.lowercase()
        return lower.contains("uber") || lower.contains("didi")
    }

    private fun captureScreenWithOcr() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.R) {
            Log.e("DriverAI_OCR", "takeScreenshot requiere Android 11+")
            isProcessingOcr = false
            return
        }

        isProcessingOcr = true

        try {
            takeScreenshot(
                0,
                mainExecutor,
                object : TakeScreenshotCallback {
                    override fun onSuccess(result: ScreenshotResult) {
                        try {
                            val hardwareBitmap = Bitmap.wrapHardwareBuffer(
                                result.hardwareBuffer,
                                result.colorSpace
                            )

                            if (hardwareBitmap == null) {
                                Log.e("DriverAI_OCR", "Bitmap null")
                                result.hardwareBuffer.close()
                                isProcessingOcr = false
                                return
                            }

                            val softwareBitmap = hardwareBitmap.copy(
                                Bitmap.Config.ARGB_8888,
                                false
                            )

                            result.hardwareBuffer.close()

                            runOcr(softwareBitmap)
                        } catch (e: Exception) {
                            Log.e("DriverAI_OCR", "Error preparando screenshot: ${e.message}")
                            isProcessingOcr = false
                        }
                    }

                    override fun onFailure(errorCode: Int) {
                        Log.e("DriverAI_OCR", "Error takeScreenshot code=$errorCode")
                        isProcessingOcr = false
                    }
                }
            )
        } catch (e: Exception) {
            Log.e("DriverAI_OCR", "Excepción takeScreenshot: ${e.message}")
            isProcessingOcr = false
        }
    }

    private fun runOcr(bitmap: Bitmap) {
        val image = InputImage.fromBitmap(bitmap, 0)

        val recognizer = TextRecognition.getClient(
            TextRecognizerOptions.DEFAULT_OPTIONS
        )

        recognizer.process(image)
            .addOnSuccessListener { visionText ->
                val text = visionText.text.trim()

                Log.d("DriverAI_OCR", "Texto OCR:\n$text")

                if (text.isBlank()) {
                    isProcessingOcr = false
                    return@addOnSuccessListener
                }

                if (text == lastOcrText) {
                    isProcessingOcr = false
                    return@addOnSuccessListener
                }

                lastOcrText = text

                val offer = parseOffer(text)

                if (offer == null) {
                    Log.d("DriverAI_OCR", "OCR leído, pero no parece oferta válida")
                    isProcessingOcr = false
                    return@addOnSuccessListener
                }

                Log.d("DriverAI_OCR", "Oferta OCR detectada: $offer")

                showNativeOverlay(offer)

                isProcessingOcr = false
            }
            .addOnFailureListener { e ->
                Log.e("DriverAI_OCR", "Error OCR: ${e.message}")
                isProcessingOcr = false
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
            profitPerKm >= 225 -> "NARANJA"
            else -> "RECHAZAR"
        }

        val color = when (decision) {
            "ACEPTAR" -> "#22C55E"
            "NARANJA" -> "#F59E0B"
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

        val regex = Regex("""₡\s*([0-9][0-9 .,\u00A0]*)""")

        val match = regex.find(normalized) ?: return 0.0

        return parseMoney(match.groupValues[1])
    }

    private fun extractDeliveryTotal(text: String): TimeDistance? {
        val regex = Regex(
            """Total[:\s]+([0-9]+)\s*min\s*\(([0-9]+(?:[.,][0-9]+)?)\s*km\)""",
            RegexOption.IGNORE_CASE
        )

        val match = regex.find(text) ?: return null

        return TimeDistance(
            minutes = match.groupValues[1].toIntOrNull() ?: 0,
            km = parseDecimal(match.groupValues[2])
        )
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

    private fun showNativeOverlay(offer: OfferResult) {
        removeOverlay()

        val layout = LinearLayout(this)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(34, 22, 34, 22)
        layout.setBackgroundColor(Color.parseColor("#F2151515"))

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

        val decisionColor = Color.parseColor(offer.color)

        layout.addView(label(offer.decision, 18f, decisionColor))
        layout.addView(label("₡${"%.2f".format(offer.profitPerKm)} / km", 25f, decisionColor))
        layout.addView(label("🚗 ${"%.1f".format(offer.totalKm)} km  |  ⏱ ${offer.totalMinutes} min", 14f, Color.WHITE))
        layout.addView(label("💰 ₡${"%.0f".format(offer.fare)}  |  📈 ₡${"%.0f".format(offer.netProfit)}", 13f, Color.WHITE))

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 90

        try {
            val wm = getSystemService(WINDOW_SERVICE) as WindowManager
            wm.addView(layout, params)
            overlayView = layout
            Log.d("DriverAI_OCR", "Overlay mostrado")
        } catch (e: Exception) {
            Log.e("DriverAI_OCR", "Error mostrando overlay: ${e.message}")
        }

        mainHandler.postDelayed({
            removeOverlay()
        }, 8500)
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