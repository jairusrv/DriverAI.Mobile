package com.driverai.driverai_mobile

import android.content.Context
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object DriverAiOcrSampleLogger {

    fun save(
        context: Context,
        text: String
    ) {
        try {
            val dir = File(
                context.getExternalFilesDir(null),
                "ocr_samples"
            )

            if (!dir.exists()) {
                dir.mkdirs()
            }

            val file = File(
                dir,
                "failed_ocr_samples.txt"
            )

            val timestamp = SimpleDateFormat(
                "yyyy-MM-dd HH:mm:ss",
                Locale.US
            ).format(Date())

            file.appendText(
                """
                
                ==============================
                $timestamp
                ==============================
                
                $text
                
                """.trimIndent()
            )

        } catch (_: Exception) {
        }
    }
}