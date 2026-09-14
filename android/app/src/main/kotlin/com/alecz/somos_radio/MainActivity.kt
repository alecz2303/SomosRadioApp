package com.alecz.somos_radio

import android.app.NotificationChannel
import android.app.NotificationManager
import android.os.Build
import android.os.Bundle
import com.ryanheise.audioservice.AudioServiceActivity

class MainActivity : AudioServiceActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        createNotificationChannels()
    }

    private fun createNotificationChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return

        val manager = getSystemService(NotificationManager::class.java)
        val updatesChannel = NotificationChannel(
            "somos_radio_updates",
            "Avisos de Somos Radio",
            NotificationManager.IMPORTANCE_HIGH,
        ).apply {
            description = "Notificaciones, promociones y avisos de Somos Radio"
            enableVibration(true)
        }

        manager.createNotificationChannel(updatesChannel)
    }
}
