package com.alecz.somos_radio

import android.app.Activity
import android.content.ComponentName
import android.os.Bundle
import androidx.media3.session.MediaController
import androidx.media3.session.SessionToken

class WidgetPlaybackActivity : Activity() {
    companion object {
        const val EXTRA_STATION_SLUG = "station_slug"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val slug = intent.getStringExtra(EXTRA_STATION_SLUG)
        val station = when (slug) {
            "somos-radio-89-1" -> Station(
                slug = slug,
                streamUrl = "https://stream.freepi.io/8332/live",
                title = "Somos Radio 89.1 FM",
                city = "Tuxtla Gutiérrez",
                artworkUrl = "https://raw.githubusercontent.com/alecz2303/SomosRadioApp/main/assets/stations/somos_89_1.webp",
            )
            "somos-radio-102-9" -> Station(
                slug = slug,
                streamUrl = "https://stream.freepi.io/8334/live",
                title = "Somos Radio 102.9 FM",
                city = "San Cristóbal de las Casas",
                artworkUrl = "https://raw.githubusercontent.com/alecz2303/SomosRadioApp/main/assets/stations/somos_102_9.webp",
            )
            else -> null
        }

        if (station == null) {
            finish()
            return
        }

        val token = SessionToken(this, ComponentName(this, SomosRadioPlaybackService::class.java))
        val future = MediaController.Builder(this, token).buildAsync()
        future.addListener({
            try {
                val controller = future.get()
                controller.setMediaItem(
                    SomosRadioPlaybackService.stationItem(
                        station.slug,
                        station.streamUrl,
                        station.title,
                        station.city,
                        station.artworkUrl,
                    ),
                )
                controller.prepare()
                controller.play()
                controller.release()
            } finally {
                finish()
                overridePendingTransition(0, 0)
            }
        }, mainExecutor)
    }

    private data class Station(
        val slug: String,
        val streamUrl: String,
        val title: String,
        val city: String,
        val artworkUrl: String,
    )
}
