package com.driverai.driverai_mobile

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    companion object {
        var lastNotificationProvider: String? = null
        var lastNotificationText: String? = null

        private const val SCREEN_CAPTURE_REQUEST_CODE = 9001
    }

    private val notificationChannel = "driverai/notifications"
    private val minimizeChannel = "com.driverai.minimize"
    private val captureChannel = "driverai/capture"

    private var pendingCaptureResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationChannel
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "openNotificationSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    )
                    result.success(true)
                }

                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }

                "openOverlaySettings" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    startActivity(intent)
                    result.success(true)
                }

                "canDrawOverlays" -> {
                    result.success(Settings.canDrawOverlays(this))
                }

                "openBatteryOptimizationSettings" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val intent = Intent(
                            Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS
                        )
                        intent.data = Uri.parse("package:$packageName")
                        startActivity(intent)
                    }
                    result.success(true)
                }

                "isBatteryOptimizationIgnored" -> {
                    result.success(isBatteryOptimizationIgnored())
                }

                "openAccessibilitySettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    )
                    result.success(true)
                }

                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityServiceEnabled())
                }

                "getLastNotification" -> {
                    result.success(
                        mapOf(
                            "provider" to lastNotificationProvider,
                            "text" to lastNotificationText
                        )
                    )
                }

                else -> result.notImplemented()
            }
        }

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

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            captureChannel
        ).setMethodCallHandler { call, result ->

            when (call.method) {

                "startCapture" -> {
                    startScreenCapture(result)
                }

                "stopCapture" -> {
                    stopService(
                        Intent(
                            this,
                            DriverAiCaptureService::class.java
                        )
                    )
                    
                    result.success(true)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun startScreenCapture(result: MethodChannel.Result) {
        if (!Settings.canDrawOverlays(this)) {
            result.error(
                "OVERLAY_PERMISSION_MISSING",
                "Permiso de mostrar sobre otras apps no concedido",
                null
            )
            return
        }

        pendingCaptureResult = result

        val projectionManager =
            getSystemService(
                Context.MEDIA_PROJECTION_SERVICE
            ) as MediaProjectionManager

        startActivityForResult(
            projectionManager.createScreenCaptureIntent(),
            SCREEN_CAPTURE_REQUEST_CODE
        )
    }

    override fun onActivityResult(
        requestCode: Int,
        resultCode: Int,
        data: Intent?
    ) {
        super.onActivityResult(
            requestCode,
            resultCode,
            data
        )

        if (requestCode != SCREEN_CAPTURE_REQUEST_CODE) return

        val result = pendingCaptureResult
        pendingCaptureResult = null

        if (resultCode != Activity.RESULT_OK || data == null) {
            result?.error(
                "CAPTURE_PERMISSION_DENIED",
                "Permiso de captura de pantalla denegado",
                null
            )
            return
        }

       val serviceIntent =
    Intent(
        this,
        DriverAiCaptureService::class.java
    )

serviceIntent.putExtra(
    "resultCode",
    resultCode
)

serviceIntent.putExtra(
    "data",
    data
)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(serviceIntent)
        } else {
            startService(serviceIntent)
        }

        result?.success(true)
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )

        if (enabledListeners.isNullOrBlank()) {
            return false
        }

        return enabledListeners.lowercase()
            .contains(packageName.lowercase())
    }

    private fun isBatteryOptimizationIgnored(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.M) {
            return true
        }

        val powerManager =
            getSystemService(
                Context.POWER_SERVICE
            ) as PowerManager

        return powerManager.isIgnoringBatteryOptimizations(
            packageName
        )
    }

    private fun isAccessibilityServiceEnabled(): Boolean {
        val enabledServices =
            Settings.Secure.getString(
                contentResolver,
                Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
            ) ?: return false

        val serviceShort =
            "$packageName/.DriverAiAccessibilityService"

        val serviceFull =
            "$packageName/$packageName.DriverAiAccessibilityService"

        val enabledLower =
            enabledServices.lowercase()

        return enabledLower.contains(serviceShort.lowercase()) ||
            enabledLower.contains(serviceFull.lowercase()) ||
            enabledLower.contains("driveraiaccessibilityservice")
    }
}