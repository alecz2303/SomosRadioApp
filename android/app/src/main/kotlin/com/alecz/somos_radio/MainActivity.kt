package com.alecz.somos_radio

import android.content.Intent
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    companion object {
        private const val CHANNEL = "somos_radio/widget"
        const val EXTRA_STATION_SLUG = "station_slug"
    }

    private var methodChannel: MethodChannel? = null
    private var pendingStationSlug: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        pendingStationSlug = intent?.getStringExtra(EXTRA_STATION_SLUG)

        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "getInitialStation" -> {
                        result.success(pendingStationSlug)
                        pendingStationSlug = null
                    }
                    else -> result.notImplemented()
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)

        val stationSlug = intent.getStringExtra(EXTRA_STATION_SLUG) ?: return
        pendingStationSlug = stationSlug
        methodChannel?.invokeMethod("stationSelected", stationSlug)
    }
}
