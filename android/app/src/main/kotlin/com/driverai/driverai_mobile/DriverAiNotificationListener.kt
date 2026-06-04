package com.driverai.driverai_mobile

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class DriverAiNotificationListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val packageName = sbn.packageName

        val extras = sbn.notification.extras

        val title = extras.getCharSequence("android.title")?.toString() ?: ""
        val text = extras.getCharSequence("android.text")?.toString() ?: ""
        val bigText = extras.getCharSequence("android.bigText")?.toString() ?: ""

        val fullText = listOf(title, text, bigText)
            .filter { it.isNotBlank() }
            .joinToString("\n")

        if (fullText.isBlank()) return

        Log.d("DriverAI", "Notificación capturada: $fullText")

        MainActivity.lastNotificationProvider = packageName
        MainActivity.lastNotificationText = fullText
    }
}