package com.driverai.driverai_mobile

import android.app.*
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.DisplayMetrics
import android.util.Log
import android.view.WindowManager
import androidx.core.app.NotificationCompat
import java.nio.ByteBuffer

class DriverAiCaptureService : Service() {

    companion object {
        const val CHANNEL_ID = "driverai_capture"
        const val NOTIFICATION_ID = 1001

        var mediaProjection: MediaProjection? = null
    }

    private val handler = Handler(Looper.getMainLooper())

    private lateinit var imageReader: ImageReader
    private var virtualDisplay: VirtualDisplay? = null

    private val ocrProcessor = DriverAiOcrProcessor()

    private lateinit var overlayManager: DriverAiOverlayManager

    private var isProcessing = false

    private val captureRunnable = object : Runnable {
        override fun run() {

            if (!isProcessing) {
                captureFrame()
            }

            handler.postDelayed(
                this,
                1000L
            )
        }
    }

    override fun onCreate() {
        super.onCreate()

        overlayManager = DriverAiOverlayManager(this)

        createNotificationChannel()

        startForeground(
            NOTIFICATION_ID,
            buildNotification()
        )

        initializeCapture()

        handler.post(captureRunnable)

        Log.d(
            "DriverAI_CAPTURE",
            "Servicio iniciado"
        )
    }

    override fun onDestroy() {
        super.onDestroy()

        handler.removeCallbacksAndMessages(null)

        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        }

        try {
            imageReader.close()
        } catch (_: Exception) {
        }

        Log.d(
            "DriverAI_CAPTURE",
            "Servicio detenido"
        )
    }

    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    private fun initializeCapture() {

        val projection = mediaProjection

        if (projection == null) {

            Log.e(
                "DriverAI_CAPTURE",
                "MediaProjection null"
            )

            stopSelf()

            return
        }

        val wm =
            getSystemService(WINDOW_SERVICE)
                as WindowManager

        val metrics = DisplayMetrics()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.getRealMetrics(metrics)
        } else {
            @Suppress("DEPRECATION")
            wm.defaultDisplay.getRealMetrics(metrics)
        }

        imageReader = ImageReader.newInstance(
            metrics.widthPixels,
            metrics.heightPixels,
            PixelFormat.RGBA_8888,
            2
        )

        virtualDisplay =
            projection.createVirtualDisplay(
                "DriverAI",
                metrics.widthPixels,
                metrics.heightPixels,
                metrics.densityDpi,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader.surface,
                null,
                null
            )

        Log.d(
            "DriverAI_CAPTURE",
            "VirtualDisplay creada"
        )
    }

    private fun captureFrame() {

        try {

            val image =
                imageReader.acquireLatestImage()
                    ?: return

            isProcessing = true

            val bitmap =
                imageToBitmap(image)

            image.close()

            ocrProcessor.process(
                bitmap,
                onOfferDetected = { offer ->

                    overlayManager.show(
                        offer
                    )

                    Log.d(
                        "DriverAI_CAPTURE",
                        "Overlay mostrado"
                    )
                },
                onComplete = {
                    isProcessing = false
                }
            )
        } catch (e: Exception) {

            Log.e(
                "DriverAI_CAPTURE",
                "Error capturando",
                e
            )

            isProcessing = false
        }
    }

    private fun imageToBitmap(
        image: Image
    ): Bitmap {

        val plane =
            image.planes[0]

        val buffer: ByteBuffer =
            plane.buffer

        val pixelStride =
            plane.pixelStride

        val rowStride =
            plane.rowStride

        val rowPadding =
            rowStride -
                pixelStride *
                image.width

        val bitmap =
            Bitmap.createBitmap(
                image.width +
                    rowPadding / pixelStride,
                image.height,
                Bitmap.Config.ARGB_8888
            )

        bitmap.copyPixelsFromBuffer(
            buffer
        )

        return Bitmap.createBitmap(
            bitmap,
            0,
            0,
            image.width,
            image.height
        )
    }

    private fun buildNotification(): Notification {

        return NotificationCompat.Builder(
            this,
            CHANNEL_ID
        )
            .setContentTitle(
                "DriverAI"
            )
            .setContentText(
                "Analizando solicitudes..."
            )
            .setSmallIcon(
                android.R.drawable.ic_menu_search
            )
            .setOngoing(true)
            .build()
    }

    private fun createNotificationChannel() {

        if (Build.VERSION.SDK_INT <
            Build.VERSION_CODES.O
        ) return

        val channel =
            NotificationChannel(
                CHANNEL_ID,
                "DriverAI Capture",
                NotificationManager.IMPORTANCE_LOW
            )

        val manager =
            getSystemService(
                NotificationManager::class.java
            )

        manager.createNotificationChannel(
            channel
        )
    }
}