package com.alecz.somos_radio

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class SomosRadioWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { appWidgetId ->
            val views = RemoteViews(context.packageName, R.layout.somos_radio_widget)

            views.setOnClickPendingIntent(
                R.id.widget_root,
                launchAppIntent(context, appWidgetId * 10),
            )
            views.setOnClickPendingIntent(
                R.id.widget_station_891,
                launchStationIntent(
                    context,
                    appWidgetId * 10 + 1,
                    "somos-radio-89-1",
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_station_1029,
                launchStationIntent(
                    context,
                    appWidgetId * 10 + 2,
                    "somos-radio-102-9",
                ),
            )
            views.setOnClickPendingIntent(
                R.id.widget_open_app,
                launchAppIntent(context, appWidgetId * 10 + 3),
            )

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }

    private fun launchStationIntent(
        context: Context,
        requestCode: Int,
        stationSlug: String,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "${context.packageName}.PLAY_STATION.$stationSlug"
            putExtra(MainActivity.EXTRA_STATION_SLUG, stationSlug)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }

    private fun launchAppIntent(
        context: Context,
        requestCode: Int,
    ): PendingIntent {
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "${context.packageName}.OPEN_APP"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

        return PendingIntent.getActivity(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
