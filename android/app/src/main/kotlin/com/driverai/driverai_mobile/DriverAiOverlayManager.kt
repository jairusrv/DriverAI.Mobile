package com.driverai.driverai_mobile

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView

class DriverAiOverlayManager(
    private val context: Context
) {
    private var overlayView: LinearLayout? = null

    fun show(offer: DriverAiOcrProcessor.OfferResult) {
        remove()

        val layout = LinearLayout(context)
        layout.orientation = LinearLayout.VERTICAL
        layout.setPadding(34, 22, 34, 22)
        layout.setBackgroundColor(Color.parseColor("#F2151515"))

        fun label(
            value: String,
            size: Float,
            textColor: Int,
            bold: Boolean = true
        ): TextView {
            val tv = TextView(context)
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
        layout.addView(label("🚗 ${"%.1f".format(offer.totalKm)} km | ⏱ ${offer.totalMinutes} min", 14f, Color.WHITE))
        layout.addView(label("💰 ₡${"%.0f".format(offer.fare)} | 📈 ₡${"%.0f".format(offer.netProfit)}", 13f, Color.WHITE))

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = 90

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.addView(layout, params)

        overlayView = layout

        layout.postDelayed({
            remove()
        }, 8500)
    }

    fun remove() {
        val view = overlayView ?: return

        try {
            val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
            wm.removeView(view)
        } catch (_: Exception) {
        }

        overlayView = null
    }
}