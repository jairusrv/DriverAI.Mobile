package com.driverai.driverai_mobile

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val notificationChannel =
        "driverai/notifications"

    private val minimizeChannel =
        "com.driverai.minimize"

    override fun configureFlutterEngine(
        flutterEngine: FlutterEngine
    ) {
        super.configureFlutterEngine(
            flutterEngine
        )

        // =========================
        // Notification Channel
        // =========================

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationChannel
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "openNotificationSettings" -> {

                    startActivity(
                        Intent(
                            Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS
                        )
                    )

                    result.success(true)
                }

                "getLastNotification" -> {

                    result.success(
                        mapOf(
                            "provider" to NotificationBridge.lastProvider,
                            "text" to NotificationBridge.lastNotificationText
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }

        // =========================
        // Minimize Channel
        // =========================

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            minimizeChannel
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "minimize" -> {

                    moveTaskToBack(true)

                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }
}