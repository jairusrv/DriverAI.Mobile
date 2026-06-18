package com.driverai.driverai_mobile

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class DriverAiNotificationListener :
    NotificationListenerService() {

    override fun onNotificationPosted(
        sbn: StatusBarNotification
    ) {

        val packageName =
            sbn.packageName.lowercase()

        val isSupported =
            packageName.contains("uber") ||
            packageName.contains("didi") ||
            packageName.contains("indriver")

        if (!isSupported)
            return

        Log.d(
            "DriverAI_NOTIFY",
            "Notificación detectada: $packageName"
        )

        DriverAiCaptureService.triggerIntensiveScan()
    }
}