package com.driverai.driverai_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.Image
import android.media.ImageReader
import android.media.projection.MediaProjection
import android.media.projection.MediaProjection.Callback
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.util.Log
import androidx.core.app.NotificationCompat
import java.nio.ByteBuffer

class DriverAiCaptureService : Service() {

    companion object {
        private const val CHANNEL_ID = "driverai_capture"
        private const val NOTIFICATION_ID = 1001

        private const val NORMAL_SCAN_DELAY_MS = 1000L
        private const val INTENSIVE_SCAN_DELAY_MS = 300L
        private const val INTENSIVE_SCAN_COUNT = 50

        var activeInstance: DriverAiCaptureService? = null

        fun triggerIntensiveScan() {
            activeInstance?.startIntensiveScan()
        }
    }
    private lateinit var historyRepository: DriverAiHistoryRepository
    private val handler = Handler(Looper.getMainLooper())

    private var imageReader: ImageReader? = null
    private var virtualDisplay: VirtualDisplay? = null
    private var mediaProjection: MediaProjection? = null

    private val ocrProcessor = DriverAiOcrProcessor()
    private lateinit var overlayManager: DriverAiOverlayManager

    private var isProcessing = false
    private var isInitialized = false
    private var isIntensiveScanRunning = false
    private var pauseOcrUntil = 0L
    private val captureRunnable = object : Runnable {
        override fun run() {
            if (!isProcessing && isInitialized) {
                captureFrame()
            }

            handler.postDelayed(
                this,
                NORMAL_SCAN_DELAY_MS
            )
        }
    }

    private val projectionCallback = object : Callback() {
        override fun onStop() {
            Log.d(
                "DriverAI_CAPTURE",
                "MediaProjection detenida por Android"
            )

            stopSelf()
        }
    }

    override fun onCreate() {
        super.onCreate()
        historyRepository = DriverAiHistoryRepository(this)
        overlayManager = DriverAiOverlayManager(this)
        activeInstance = this

        createNotificationChannel()
        startDriverAiForeground()

        Log.d(
            "DriverAI_CAPTURE",
            "Servicio iniciado"
        )
    }

    override fun onStartCommand(
        intent: Intent?,
        flags: Int,
        startId: Int
    ): Int {
        val resultCode =
            intent?.getIntExtra(
                "resultCode",
                0
            ) ?: 0

        val projectionData =
            intent?.getParcelableExtra<Intent>("data")

        if (resultCode == 0 || projectionData == null) {
            Log.e(
                "DriverAI_CAPTURE",
                "Datos de MediaProjection inválidos"
            )

            stopSelf()
            return START_NOT_STICKY
        }

        if (!isInitialized) {
            initializeMediaProjection(
                resultCode,
                projectionData
            )
        }

        return START_STICKY
    }

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)

        try {
            virtualDisplay?.release()
        } catch (_: Exception) {
        }

        try {
            imageReader?.close()
        } catch (_: Exception) {
        }

        try {
            mediaProjection?.unregisterCallback(
                projectionCallback
            )
        } catch (_: Exception) {
        }

        try {
            mediaProjection?.stop()
        } catch (_: Exception) {
        }

        virtualDisplay = null
        imageReader = null
        mediaProjection = null

        isInitialized = false
        isProcessing = false
        isIntensiveScanRunning = false

        activeInstance = null

        Log.d(
            "DriverAI_CAPTURE",
            "Servicio detenido"
        )

        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun startDriverAiForeground() {
        val notification =
            buildNotification()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION
            )
        } else {
            startForeground(
                NOTIFICATION_ID,
                notification
            )
        }
    }

    private fun initializeMediaProjection(
        resultCode: Int,
        projectionData: Intent
    ) {
        try {
            val projectionManager =
                getSystemService(
                    MEDIA_PROJECTION_SERVICE
                ) as MediaProjectionManager

            mediaProjection =
                projectionManager.getMediaProjection(
                    resultCode,
                    projectionData
                )

            mediaProjection?.registerCallback(
                projectionCallback,
                handler
            )

            initializeCapture()

            isInitialized = true

            handler.post(
                captureRunnable
            )

            Log.d(
                "DriverAI_CAPTURE",
                "MediaProjection inicializada"
            )
        } catch (e: Exception) {
            Log.e(
                "DriverAI_CAPTURE",
                "Error inicializando MediaProjection",
                e
            )

            stopSelf()
        }
    }

    private fun initializeCapture() {
        val projection =
            mediaProjection ?: run {
                Log.e(
                    "DriverAI_CAPTURE",
                    "MediaProjection null"
                )

                stopSelf()
                return
            }

        val metrics =
            resources.displayMetrics

        val width =
            metrics.widthPixels

        val height =
            metrics.heightPixels

        val density =
            metrics.densityDpi

        imageReader =
            ImageReader.newInstance(
                width,
                height,
                PixelFormat.RGBA_8888,
                2
            )

        virtualDisplay =
            projection.createVirtualDisplay(
                "DriverAI",
                width,
                height,
                density,
                DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
                imageReader!!.surface,
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

            if (System.currentTimeMillis() < pauseOcrUntil) {
            return
            }
            val reader =
                imageReader ?: return

            val image =
                reader.acquireLatestImage() ?: return

            isProcessing = true

            val bitmap =
                imageToBitmap(image)

            image.close()

            ocrProcessor.process(
                bitmap,
                onOfferDetected = { offer ->
    pauseOcrUntil = System.currentTimeMillis() + 30_000L

    var finalOffer = offer

val destination =
    offer.destinationText

if (!destination.isNullOrBlank()) {

    val location =
        DriverAiGeocoder.geocode(
            this,
            destination
        )

    if (location != null) {

        val redZone =
            DriverAiRedZoneDetector.findMatchingZone(
                this,
                location.lat,
                location.lng
            )

        if (redZone != null) {

            finalOffer =
                offer.copy(
                    decision = "RECHAZAR",
                    color = "#EF4444"
                )

            Log.d(
                "DriverAI_REDZONE",
                "Destino en zona roja: $destination"
            )
        }
    }
}

historyRepository.saveOffer(finalOffer)

overlayManager.show(finalOffer)

    Log.d(
        "DriverAI_CAPTURE",
        "Overlay mostrado, oferta guardada, OCR pausado 30s"
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
            rowStride - pixelStride * image.width

        val fullBitmap =
            Bitmap.createBitmap(
                image.width + rowPadding / pixelStride,
                image.height,
                Bitmap.Config.ARGB_8888
            )

        fullBitmap.copyPixelsFromBuffer(
            buffer
        )

        val croppedBitmap =
            Bitmap.createBitmap(
                fullBitmap,
                0,
                0,
                image.width,
                image.height
            )

        fullBitmap.recycle()

        return croppedBitmap
    }

    private fun buildNotification(): Notification {
        return NotificationCompat.Builder(
            this,
            CHANNEL_ID
        )
            .setContentTitle("DriverAI")
            .setContentText("Analizando solicitudes")
            .setSmallIcon(android.R.drawable.ic_menu_search)
            .setOngoing(true)
            .build()
    }

    private fun startIntensiveScan() {
        if (!isInitialized)
            return

        if (isIntensiveScanRunning)
            return

        isIntensiveScanRunning = true

        Log.d(
            "DriverAI_CAPTURE",
            "OCR intensivo iniciado"
        )

        var count = 0

        val intensiveRunnable =
            object : Runnable {
                override fun run() {
                    if (!isInitialized) {
                        isIntensiveScanRunning = false
                        return
                    }

                    if (!isProcessing) {
                        captureFrame()
                    }

                    count++

                    if (count < INTENSIVE_SCAN_COUNT) {
                        handler.postDelayed(
                            this,
                            INTENSIVE_SCAN_DELAY_MS
                        )
                    } else {
                        isIntensiveScanRunning = false

                        Log.d(
                            "DriverAI_CAPTURE",
                            "OCR intensivo finalizado"
                        )
                    }
                }
            }

        handler.post(
            intensiveRunnable
        )
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O)
            return

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