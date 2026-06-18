package com.driverai.driverai_mobile

import android.content.ContentValues
import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class DriverAiHistoryRepository(
    context: Context
) : SQLiteOpenHelper(
    context,
    "driverai_history.db",
    null,
    1
) {

    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            """
            CREATE TABLE ride_history(
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                provider TEXT NOT NULL,
                decision TEXT NOT NULL,
                fare REAL NOT NULL,
                total_km REAL NOT NULL,
                total_minutes INTEGER NOT NULL,
                profit_per_km REAL NOT NULL,
                net_profit REAL NOT NULL,
                created_at INTEGER NOT NULL
            )
            """.trimIndent()
        )
    }

    override fun onUpgrade(
        db: SQLiteDatabase,
        oldVersion: Int,
        newVersion: Int
    ) {
    }

    fun saveOffer(
        offer: DriverAiOcrProcessor.OfferResult
    ) {
        val values = ContentValues().apply {
            put("provider", offer.provider)
            put("decision", offer.decision)
            put("fare", offer.fare)
            put("total_km", offer.totalKm)
            put("total_minutes", offer.totalMinutes)
            put("profit_per_km", offer.profitPerKm)
            put("net_profit", offer.netProfit)
            put("created_at", System.currentTimeMillis())
        }

        writableDatabase.insert(
            "ride_history",
            null,
            values
        )
    }
}