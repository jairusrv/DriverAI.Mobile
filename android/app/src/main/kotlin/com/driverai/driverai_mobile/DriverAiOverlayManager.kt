package com.driverai.driverai_mobile

import android.content.Context
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.view.Gravity
import android.view.WindowManager
import android.widget.LinearLayout
import android.widget.TextView
import java.text.DecimalFormat
import java.text.DecimalFormatSymbols
import java.util.Locale

class DriverAiOverlayManager(
    private val context: Context
) {
    private var overlayView: LinearLayout? = null

    fun show(offer: DriverAiOcrProcessor.OfferResult) {
        remove()

        val decisionColor = Color.parseColor(offer.color)

        val container = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(dp(18), dp(14), dp(18), dp(14))
            background = roundedBg("#E6151515", dp(16), decisionColor, dp(2))
            gravity = Gravity.CENTER
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                elevation = dp(12).toFloat()
            }
        }

        container.addView(
            text(
                offer.decision,
                24f,
                decisionColor,
                true
            )
        )

        container.addView(
            text(
                "${money(offer.profitPerKm)} / km",
                30f,
                decisionColor,
                true
            )
        )

        container.addView(
            row(
                "${formatKm(offer.totalKm)} km",
                "${offer.totalMinutes} min"
            )
        )

        container.addView(
            row(
                "Tarifa ${money(offer.fare)}",
                "Neto ${money(offer.netProfit)}"
            )
        )

        val params = WindowManager.LayoutParams(
            dp(310),
            WindowManager.LayoutParams.WRAP_CONTENT,
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )

        params.gravity = Gravity.TOP or Gravity.CENTER_HORIZONTAL
        params.y = dp(58)

        val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
        wm.addView(container, params)

        overlayView = container

        container.postDelayed({
            remove()
        }, 30_000)
    }

    private fun row(left: String, right: String): LinearLayout {
        return LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dp(4), 0, 0)

            addView(
                text(
                    left,
                    15f,
                    Color.WHITE,
                    true
                ),
                LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )
            )

            addView(
                text(
                    right,
                    15f,
                    Color.WHITE,
                    true
                ),
                LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )
            )
        }
    }

    private fun text(
        value: String,
        size: Float,
        color: Int,
        bold: Boolean
    ): TextView {
        return TextView(context).apply {
            text = value
            textSize = size
            setTextColor(color)
            gravity = Gravity.CENTER
            includeFontPadding = false
            if (bold) {
                typeface = Typeface.DEFAULT_BOLD
            }
        }
    }

    private fun roundedBg(
        color: String,
        radius: Int,
        strokeColor: Int,
        strokeWidth: Int
    ): GradientDrawable {
        return GradientDrawable().apply {
            setColor(Color.parseColor(color))
            cornerRadius = radius.toFloat()
            setStroke(strokeWidth, strokeColor)
        }
    }

    private fun money(value: Double): String {
        val symbols = DecimalFormatSymbols(Locale.US).apply {
            decimalSeparator = ','
            groupingSeparator = '.'
        }

        val formatter = DecimalFormat("#,##0.00", symbols)

        return "₡${formatter.format(value)}"
    }

    private fun formatKm(value: Double): String {
        return "%.1f".format(Locale.US, value).replace(".", ",")
    }

    private fun dp(value: Int): Int {
        return (value * context.resources.displayMetrics.density).toInt()
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