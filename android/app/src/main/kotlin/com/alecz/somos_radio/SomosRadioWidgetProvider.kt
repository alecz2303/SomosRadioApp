package com.alecz.somos_radio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import androidx.media.MediaBrowserServiceCompat
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat

class SomosRadioWidgetProvider : AppWidgetProvider() {
    companion object {
        private const val ACTION_PLAY_STATION = "com.alecz.somos_radio.PLAY_STATION"
        private const val EXTRA_STATION_SLUG = "station_slug"
        private const val STATION_891 = "somos-radio-89-1"
        private const val STATION_1029 = "somos-radio-102-9"
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.somos_radio_widget)

            views.setOnClickPendingIntent(
                R.id.widget_station_891,
                stationPendingIntent(context, appWidgetId * 10 + 1, STATION_891),
            )
            views.setOnClickPendingIntent(
                R.id.widget_station_1029,
                stationPendingIntent(context, appWidgetId * 10 + 2, STATION_1029),
            )

            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }

            if (launchIntent != null) {
                val openApp = PendingIntent.getActivity(
                    context,
                    appWidgetId * 10 + 3,
                    launchIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_root, openApp)
                views.setOnClickPendingIntent(R.id.widget_open_app, openApp)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action != ACTION_PLAY_STATION) return
        val stationSlug = intent.getStringExtra(EXTRA_STATION_SLUG) ?: return
        playStation(context, stationSlug)
    }

    private fun stationPendingIntent(
        context: Context,
        requestCode: Int,
        stationSlug: String,
    ): PendingIntent {
        val intent = Intent(context, SomosRadioWidgetProvider::class.java).apply {
            action = ACTION_PLAY_STATION
            putExtra(EXTRA_STATION_SLUG, stationSlug)
        }

        return PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun playStation(context: Context, stationSlug: String) {
        val pendingResult = goAsync()
        lateinit var browser: MediaBrowserCompat

        val callback = object : MediaBrowserCompat.ConnectionCallback() {
            override fun onConnected() {
                try {
                    val controller = MediaControllerCompat(context, browser.sessionToken)
                    controller.transportControls.playFromMediaId(stationSlug, Bundle.EMPTY)
                } finally {
                    browser.disconnect()
                    pendingResult.finish()
                }
            }

            override fun onConnectionFailed() {
                browser.disconnect()
                pendingResult.finish()
            }

            override fun onConnectionSuspended() {
                browser.disconnect()
                pendingResult.finish()
            }
        }

        browser = MediaBrowserCompat(
            context,
            ComponentName(context.packageName, "com.ryanheise.audioservice.AudioService"),
            callback,
            null,
        )
        browser.connect()
    }
}
