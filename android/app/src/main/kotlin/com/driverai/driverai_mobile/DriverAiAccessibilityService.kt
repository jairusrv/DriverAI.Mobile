package com.driverai.driverai_mobile

import android.accessibilityservice.AccessibilityService
import android.util.Log
import android.view.accessibility.AccessibilityEvent

class DriverAiAccessibilityService : AccessibilityService() {

    companion object {
        private const val TAG = "DriverAI_ACCESS"
    }

    override fun onServiceConnected() {
        super.onServiceConnected()

        Log.d(
            TAG,
            "AccessibilityService conectado"
        )
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        val packageName =
            event?.packageName?.toString() ?: return

        if (!isSupportedApp(packageName))
            return

        /*
         * Este servicio NO lee datos sensibles ni analiza el árbol visual.
         *
         * Su única función en DriverAI es detectar actividad de apps soportadas
         * como Uber Driver o DiDi Driver para activar temporalmente el OCR rápido.
         *
         * Flujo:
         * Uber/DiDi cambia pantalla o genera evento
         * -> AccessibilityService lo detecta
         * -> DriverAiCaptureService acelera capturas OCR por unos segundos
         * -> DriverAiOcrProcessor decide si existe una oferta válida
         */
        DriverAiCaptureService.triggerIntensiveScan()

        Log.d(
            TAG,
            "OCR intensivo solicitado por evento de $packageName"
        )
    }

    override fun onInterrupt() {
        Log.d(
            TAG,
            "AccessibilityService interrumpido"
        )
    }

    private fun isSupportedApp(
        packageName: String
    ): Boolean {
        val lower =
            packageName.lowercase()

        return lower.contains("uber") ||
            lower.contains("didi") ||
            lower.contains("indriver")
    }
}