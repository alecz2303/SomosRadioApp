package com.alecz.somos_radio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class SomosRadioWidgetProvider : AppWidgetProvider() {
    companion object {
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

    private fun stationPendingIntent(
        context: Context,
        requestCode: Int,
        stationSlug: String,
    ): PendingIntent {
        val intent = Intent(context, WidgetPlaybackActivity::class.java).apply {
            putExtra(WidgetPlaybackActivity.EXTRA_STATION_SLUG, stationSlug)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_NO_ANIMATION or
                Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
        }

        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
