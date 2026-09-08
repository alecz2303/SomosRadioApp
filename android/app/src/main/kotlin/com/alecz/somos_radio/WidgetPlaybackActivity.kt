package com.alecz.somos_radio

import android.content.ComponentName
import android.os.Bundle
import android.support.v4.media.MediaBrowserCompat
import android.support.v4.media.session.MediaControllerCompat
import com.ryanheise.audioservice.AudioServiceActivity

class WidgetPlaybackActivity : AudioServiceActivity() {
    companion object {
        const val EXTRA_STATION_SLUG = "station_slug"
    }

    private var browser: MediaBrowserCompat? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val stationSlug = intent.getStringExtra(EXTRA_STATION_SLUG)
        if (stationSlug.isNullOrBlank()) {
            finish()
            return
        }

        val callback = object : MediaBrowserCompat.ConnectionCallback() {
            override fun onConnected() {
                try {
                    val connectedBrowser = browser ?: return
                    val controller = MediaControllerCompat(
                        this@WidgetPlaybackActivity,
                        connectedBrowser.sessionToken,
                    )
                    controller.transportControls.playFromMediaId(stationSlug, Bundle.EMPTY)
                } finally {
                    closeBrowserAndFinish()
                }
            }

            override fun onConnectionFailed() {
                closeBrowserAndFinish()
            }

            override fun onConnectionSuspended() {
                closeBrowserAndFinish()
            }
        }

        browser = MediaBrowserCompat(
            this,
            ComponentName(packageName, "com.ryanheise.audioservice.AudioService"),
            callback,
            null,
        ).also { it.connect() }
    }

    private fun closeBrowserAndFinish() {
        browser?.disconnect()
        browser = null
        finish()
        overridePendingTransition(0, 0)
    }

    override fun onDestroy() {
        browser?.disconnect()
        browser = null
        super.onDestroy()
    }
}
