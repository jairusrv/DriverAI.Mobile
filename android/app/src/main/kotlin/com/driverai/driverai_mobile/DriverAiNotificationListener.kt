package com.driverai.driverai_mobile

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class DriverAiNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName ?: return

        if (!isRideApp(packageName)) return

        val extras = sbn.notification.extras

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
        val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""

        val fullText = listOf(
            packageName,
            title,
            text,
            bigText,
            subText
        ).filter { it.isNotBlank() }
            .joinToString("\n")

        Log.d("DriverAI", "Notification captured:\n$fullText")

        NotificationBridge.lastNotificationText = fullText
        NotificationBridge.lastProvider = detectProvider(packageName, fullText)
    }

    private fun isRideApp(packageName: String): Boolean {
        return packageName.contains("uber", ignoreCase = true) ||
            packageName.contains("didi", ignoreCase = true)
    }

    private fun detectProvider(packageName: String, text: String): String {
        return when {
            packageName.contains("didi", ignoreCase = true) ||
                text.contains("didi", ignoreCase = true) -> "didi"

            packageName.contains("uber", ignoreCase = true) ||
                text.contains("uber", ignoreCase = true) -> "uber"

            else -> "unknown"
        }
    }
}

object NotificationBridge {
    var lastNotificationText: String? = null
    var lastProvider: String = "unknown"
}